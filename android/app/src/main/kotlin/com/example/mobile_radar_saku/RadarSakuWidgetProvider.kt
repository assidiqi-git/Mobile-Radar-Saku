package com.example.mobile_radar_saku

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.util.Log
import android.view.View
import android.widget.RemoteViews

/**
 * AppWidgetProvider untuk Home Screen Widget Radar Saku.
 *
 * Membaca data dari SharedPreferences "HomeWidgetPlugin" (ditulis oleh
 * package home_widget di sisi Dart/Flutter) dan merender dua state:
 *   - State A (Logged Out): pesan login + tombol Login
 *   - State B (Logged In):  ListView transaksi (scrollable) + tombol +
 */
class RadarSakuWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
    ) {
        Log.d(TAG, "onUpdate called for ${appWidgetIds.size} widget(s)")
        for (appWidgetId in appWidgetIds) {
            try {
                updateWidget(context, appWidgetManager, appWidgetId)
            } catch (e: Exception) {
                Log.e(TAG, "Error updating widget id=$appWidgetId", e)
            }
        }
    }

    companion object {
        private const val TAG = "RadarSakuWidget"

        /**
         * Dipanggil dari [onUpdate] untuk setiap widget instance.
         * Bisa dipanggil ulang dari luar untuk force-refresh.
         */
        fun updateWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int,
        ) {
            Log.d(TAG, "updateWidget id=$appWidgetId")
            try {
                // Baca data yang disimpan home_widget package (Dart side)
                val prefs = context.getSharedPreferences("HomeWidgetPlugin", Context.MODE_PRIVATE)
                val isLoggedIn = prefs.getString("is_logged_in", "false") == "true"
                Log.d(TAG, "isLoggedIn=$isLoggedIn")

                val views = RemoteViews(context.packageName, R.layout.widget_radar_saku)

                if (isLoggedIn) {
                    // ===== State B: Logged In =====
                    views.setViewVisibility(R.id.layout_logged_out, View.GONE)
                    views.setViewVisibility(R.id.layout_logged_in, View.VISIBLE)

                    // Hubungkan ListView ke RadarSakuWidgetService (RemoteViewsService)
                    val serviceIntent = Intent(context, RadarSakuWidgetService::class.java).apply {
                        putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId)
                        // Data harus unique per widget agar Android tidak gunakan cache lama
                        data = Uri.parse(toUri(Intent.URI_INTENT_SCHEME))
                    }
                    views.setRemoteAdapter(R.id.list_transactions, serviceIntent)
                    views.setEmptyView(R.id.list_transactions, R.id.tv_no_transactions)

                    // Tombol "+" — tambah transaksi
                    val addTxIntent = Intent(context, MainActivity::class.java).apply {
                        action = "com.example.mobile_radar_saku.WIDGET_CLICK"
                        data = Uri.parse("radarsaku://add_transaction")
                        flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                    }
                    val addTxPendingIntent = PendingIntent.getActivity(
                        context,
                        1,
                        addTxIntent,
                        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
                    )
                    views.setOnClickPendingIntent(R.id.btn_add_transaction, addTxPendingIntent)

                } else {
                    // ===== State A: Logged Out =====
                    views.setViewVisibility(R.id.layout_logged_out, View.VISIBLE)
                    views.setViewVisibility(R.id.layout_logged_in, View.GONE)

                    // Tombol "Login"
                    val loginIntent = Intent(context, MainActivity::class.java).apply {
                        action = "com.example.mobile_radar_saku.WIDGET_CLICK"
                        data = Uri.parse("radarsaku://login")
                        flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                    }
                    val loginPendingIntent = PendingIntent.getActivity(
                        context,
                        0,
                        loginIntent,
                        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
                    )
                    views.setOnClickPendingIntent(R.id.btn_login, loginPendingIntent)
                }

                appWidgetManager.updateAppWidget(appWidgetId, views)
                Log.d(TAG, "Widget updated successfully")

            } catch (e: Exception) {
                Log.e(TAG, "Fatal error in updateWidget id=$appWidgetId", e)
            }
        }
    }
}
