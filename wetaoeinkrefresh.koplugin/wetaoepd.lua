local android = require("android")

local WetaoEPD = {
    ACTION = "com.flash.force_epd_full",
}

local function bridge_available()
    return android
        and android.jni
        and android.jni.context
        and android.app
        and android.app.activity
        and android.app.activity.vm
        and android.app.activity.clazz
end

local function clear_java_exception(env)
    if env[0].ExceptionCheck(env) == 0 then
        return false
    end

    env[0].ExceptionDescribe(env)
    env[0].ExceptionClear(env)
    return true
end

local function delete_local_ref(env, ref)
    if ref ~= nil then
        env[0].DeleteLocalRef(env, ref)
    end
end

function WetaoEPD.send()
    if not bridge_available() then
        return false, "KOReader's Android JNI bridge is unavailable"
    end

    local call_ok, sent, send_error = pcall(function()
        return android.jni:context(android.app.activity.vm, function(jni)
            local env = jni.env
            local intent_class = env[0].FindClass(env, "android/content/Intent")
            if intent_class == nil then
                clear_java_exception(env)
                return false, "android.content.Intent is unavailable"
            end

            local constructor = env[0].GetMethodID(
                env,
                intent_class,
                "<init>",
                "(Ljava/lang/String;)V"
            )
            if constructor == nil then
                clear_java_exception(env)
                delete_local_ref(env, intent_class)
                return false, "Intent(String) constructor is unavailable"
            end

            local action = env[0].NewStringUTF(env, WetaoEPD.ACTION)
            local intent = env[0].NewObject(
                env,
                intent_class,
                constructor,
                action
            )

            jni:callVoidMethod(
                android.app.activity.clazz,
                "sendBroadcast",
                "(Landroid/content/Intent;)V",
                intent
            )

            local rejected = clear_java_exception(env)
            delete_local_ref(env, intent)
            delete_local_ref(env, action)
            delete_local_ref(env, intent_class)

            if rejected then
                return false, "Android rejected the WeTao E-Ink refresh broadcast"
            end
            return true
        end)
    end)

    if not call_ok then
        return false, "JNI call failed: " .. tostring(sent)
    end
    return sent, send_error
end

return WetaoEPD
