local repo_root = "."
package.path = table.concat({
    repo_root .. "/wetaoeinkrefresh.koplugin/?.lua",
    package.path,
}, ";")

local tests_run = 0
local tests_failed = 0

local function fail(message)
    error(message, 2)
end

local function assert_equal(expected, actual, label)
    if expected ~= actual then
        fail(string.format(
            "%s: expected %s, got %s",
            label or "values differ",
            tostring(expected),
            tostring(actual)
        ))
    end
end

local function assert_true(value, label)
    if value ~= true then
        fail(string.format("%s: expected true, got %s", label or "value", tostring(value)))
    end
end

local function assert_contains(haystack, needle, label)
    if not tostring(haystack):find(needle, 1, true) then
        fail(string.format(
            "%s: expected %q to contain %q",
            label or "text",
            tostring(haystack),
            needle
        ))
    end
end

local function test(name, body)
    tests_run = tests_run + 1
    local ok, err = xpcall(body, debug.traceback)
    if ok then
        io.write("PASS: ", name, "\n")
    else
        tests_failed = tests_failed + 1
        io.stderr:write("FAIL: ", name, "\n", err, "\n")
    end
end

local function fresh_module(name)
    package.loaded[name] = nil
    return require(name)
end

local function make_android(options)
    options = options or {}
    local calls = {
        deleted_refs = {},
    }
    local refs = {
        class = {},
        constructor = {},
        action = {},
        intent = {},
        activity = {},
        vm = {},
    }

    local functions = {}
    local env = { [0] = functions }

    functions.FindClass = function(received_env, name)
        assert_equal(env, received_env, "FindClass env")
        calls.class_name = name
        if options.missing_intent_class then
            return nil
        end
        return refs.class
    end

    functions.GetMethodID = function(received_env, class, method, signature)
        assert_equal(env, received_env, "GetMethodID env")
        assert_equal(refs.class, class, "constructor class")
        calls.constructor_method = method
        calls.constructor_signature = signature
        return refs.constructor
    end

    functions.NewStringUTF = function(received_env, value)
        assert_equal(env, received_env, "NewStringUTF env")
        calls.action = value
        return refs.action
    end

    functions.NewObject = function(received_env, class, constructor, action)
        assert_equal(env, received_env, "NewObject env")
        assert_equal(refs.class, class, "Intent class")
        assert_equal(refs.constructor, constructor, "Intent constructor")
        assert_equal(refs.action, action, "Intent action argument")
        return refs.intent
    end

    functions.ExceptionCheck = function(received_env)
        assert_equal(env, received_env, "ExceptionCheck env")
        return options.java_exception and 1 or 0
    end

    functions.ExceptionDescribe = function(received_env)
        assert_equal(env, received_env, "ExceptionDescribe env")
        calls.exception_described = true
    end

    functions.ExceptionClear = function(received_env)
        assert_equal(env, received_env, "ExceptionClear env")
        calls.exception_cleared = true
    end

    functions.DeleteLocalRef = function(received_env, ref)
        assert_equal(env, received_env, "DeleteLocalRef env")
        table.insert(calls.deleted_refs, ref)
    end

    local jni = {}
    function jni:context(vm, callback)
        assert_equal(refs.vm, vm, "JVM")
        self.env = env
        local first, second = callback(self)
        self.env = nil
        return first, second
    end

    function jni:callVoidMethod(object, method, signature, argument)
        calls.void_object = object
        calls.void_method = method
        calls.void_signature = signature
        calls.void_argument = argument
    end

    return {
        jni = jni,
        app = {
            activity = {
                vm = refs.vm,
                clazz = refs.activity,
            },
        },
    }, calls, refs
end

test("sends the exact WeTao full-refresh broadcast through Android JNI", function()
    local android, calls, refs = make_android()
    package.loaded.android = android
    local WetaoEPD = fresh_module("wetaoepd")

    local ok, err = WetaoEPD.send()

    assert_true(ok, "send result")
    assert_equal(nil, err, "send error")
    assert_equal("com.flash.force_epd_full", WetaoEPD.ACTION, "exported action")
    assert_equal("android/content/Intent", calls.class_name, "Intent class name")
    assert_equal("<init>", calls.constructor_method, "Intent constructor method")
    assert_equal("(Ljava/lang/String;)V", calls.constructor_signature, "Intent constructor signature")
    assert_equal("com.flash.force_epd_full", calls.action, "Intent action")
    assert_equal(refs.activity, calls.void_object, "sendBroadcast receiver")
    assert_equal("sendBroadcast", calls.void_method, "sendBroadcast method")
    assert_equal("(Landroid/content/Intent;)V", calls.void_signature, "sendBroadcast signature")
    assert_equal(refs.intent, calls.void_argument, "sendBroadcast Intent")
    assert_equal(3, #calls.deleted_refs, "deleted JNI references")
end)

test("reports and clears a Java exception raised by sendBroadcast", function()
    local android, calls = make_android({ java_exception = true })
    package.loaded.android = android
    local WetaoEPD = fresh_module("wetaoepd")

    local ok, err = WetaoEPD.send()

    assert_equal(false, ok, "send result")
    assert_contains(err, "Android rejected", "send error")
    assert_true(calls.exception_described, "exception described")
    assert_true(calls.exception_cleared, "exception cleared")
    assert_equal(3, #calls.deleted_refs, "deleted JNI references")
end)

test("fails gracefully when KOReader does not expose its Android JNI bridge", function()
    package.loaded.android = {}
    local WetaoEPD = fresh_module("wetaoepd")

    local ok, err = WetaoEPD.send()

    assert_equal(false, ok, "send result")
    assert_contains(err, "JNI bridge", "send error")
end)

local function load_plugin(is_android, send_result, send_error)
    local state = {
        registered_actions = {},
        shown_widgets = {},
        send_count = 0,
    }

    package.loaded.device = {
        isAndroid = function()
            return is_android
        end,
    }
    package.loaded.dispatcher = {
        registerAction = function(_, name, definition)
            state.registered_actions[name] = definition
        end,
    }
    package.loaded.gettext = function(text)
        return text
    end
    package.loaded["ui/uimanager"] = {
        show = function(_, widget)
            table.insert(state.shown_widgets, widget)
        end,
    }
    package.loaded["ui/widget/infomessage"] = {
        new = function(_, options)
            return options
        end,
    }
    package.loaded["ui/widget/container/widgetcontainer"] = {
        extend = function(_, definition)
            return definition
        end,
    }
    package.loaded.wetaoepd = {
        send = function()
            state.send_count = state.send_count + 1
            return send_result, send_error
        end,
    }

    local plugin = dofile("wetaoeinkrefresh.koplugin/main.lua")
    return plugin, state
end

test("disables the plugin outside Android", function()
    local plugin = load_plugin(false, true)

    assert_true(plugin.disabled, "disabled flag")
end)

test("registers a distinct Dispatcher action and More Tools menu item", function()
    local plugin, state = load_plugin(true, true)
    plugin.ui = {
        menu = {
            registerToMainMenu = function(_, instance)
                state.registered_menu_instance = instance
            end,
        },
    }

    plugin:init()
    local menu_items = {}
    plugin:addToMainMenu(menu_items)

    local action = state.registered_actions.wetao_full_eink_refresh
    assert_equal(plugin, state.registered_menu_instance, "registered menu instance")
    assert_equal("WetaoFullEinkRefresh", action.event, "Dispatcher event")
    assert_equal("Full E-Ink refresh (WeTao/DEXP)", action.title, "Dispatcher title")
    assert_true(action.general, "general Dispatcher action")
    assert_equal(
        "Full E-Ink refresh (WeTao/DEXP)",
        menu_items.wetao_eink_refresh.text,
        "menu title"
    )
    assert_equal("more_tools", menu_items.wetao_eink_refresh.sorting_hint, "menu location")

    menu_items.wetao_eink_refresh.callback()

    assert_equal(1, state.send_count, "broadcast count")
    assert_equal(0, #state.shown_widgets, "success popups")
end)

test("shows a diagnostic message when Android rejects the broadcast", function()
    local plugin, state = load_plugin(true, false, "Android rejected the broadcast")

    local handled = plugin:onWetaoFullEinkRefresh()

    assert_true(handled, "event handled")
    assert_equal(1, state.send_count, "broadcast count")
    assert_equal(1, #state.shown_widgets, "error popups")
    assert_contains(
        state.shown_widgets[1].text,
        "Android rejected the broadcast",
        "error popup text"
    )
end)

test("auto-refreshes on PageUpdate without consuming the event", function()
    local plugin, state = load_plugin(true, true)
    plugin.ui = {
        menu = {
            registerToMainMenu = function() end,
        },
    }

    plugin:init()
    local consumed = plugin:onPageUpdate(12)

    assert_equal(nil, consumed, "PageUpdate must not be consumed")
    assert_equal(1, state.send_count, "broadcast count")
    assert_equal(0, #state.shown_widgets, "auto-refresh success popups")
end)

test("skips auto-refresh on document close PageUpdate(false)", function()
    local plugin, state = load_plugin(true, true)

    plugin:onPageUpdate(false)

    assert_equal(0, state.send_count, "broadcast count on close")
end)

test("skips duplicate consecutive PageUpdate for the same page", function()
    local plugin, state = load_plugin(true, true)

    plugin:onPageUpdate(3)
    plugin:onPageUpdate(3)
    plugin:onPageUpdate(4)

    assert_equal(2, state.send_count, "broadcast count for distinct pages")
end)

test("provides plugin metadata for KOReader's plugin manager", function()
    package.loaded.gettext = function(text)
        return text
    end

    local metadata = dofile("wetaoeinkrefresh.koplugin/_meta.lua")

    assert_equal("WeTao/DEXP E-Ink refresh", metadata.fullname, "plugin fullname")
    assert_contains(metadata.description, "com.flash.force_epd_full", "plugin description")
end)

io.write(string.format("\n%d tests, %d failures\n", tests_run, tests_failed))
if tests_failed > 0 then
    os.exit(1)
end
