package com.handle_it

import android.app.KeyguardManager
import android.content.Context
import android.content.Intent
import android.os.PowerManager
import android.util.Log
import com.google.firebase.messaging.FirebaseMessagingService
import com.google.firebase.messaging.RemoteMessage

private val TAG = BackgroundService::class.java.name
class BackgroundService: FirebaseMessagingService() {

    override fun onMessageReceived(remoteMessage: RemoteMessage) {
        super.onMessageReceived(remoteMessage)
        Log.i(TAG, "message data data: ${remoteMessage.data} rawData: ${remoteMessage.rawData}")

        val prefs = applicationContext.getSharedPreferences("FlutterSharedPreferences", MODE_PRIVATE)
        val isAlert = prefs.getBoolean("flutter.isAlert", false)
        Log.i(TAG, "Result of isAlert: $isAlert")
        if(isAlert) return
        val success = prefs.edit().putBoolean("flutter.isAlert", true).commit()
        Log.i(TAG, "Result of attempted prefs.edit(): $success")

        val km = baseContext.getSystemService(Context.KEYGUARD_SERVICE) as KeyguardManager
        val kl = km.newKeyguardLock("MyKeyguardLock")
//        kl.disableKeyguard()
        val pm = baseContext.getSystemService(Context.POWER_SERVICE) as PowerManager
        val wakeLock = pm.newWakeLock(PowerManager.FULL_WAKE_LOCK or PowerManager.ACQUIRE_CAUSES_WAKEUP or PowerManager.ON_AFTER_RELEASE, TAG)
        wakeLock.acquire(5000L)

        val notificationIntent = Intent("android.intent.category.LAUNCHER")
        notificationIntent
                .setAction(Intent.ACTION_MAIN)
                .setClassName("com.handle_it", "com.handle_it.MainActivity")
                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        startActivity(notificationIntent)
//        val contentIntent = PendingIntent.getActivity(applicationContext, 0, notificationIntent, 0)

//        val mBuilder = NotificationCompat.Builder(this, "samples.flutter.dev/battery")
//                .setSmallIcon(R.drawable.launch_background)
//                .setContentIntent(contentIntent)
//                .setContentTitle("My content title")
//                .setContentText("Do the context text")
//                .setFullScreenIntent(contentIntent, true)
//
//        val mNotificationManager: NotificationManagerCompat = NotificationManagerCompat.from(applicationContext)
//        mNotificationManager.notify(0, mBuilder.build())
    }
}