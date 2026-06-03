package com.example.mobile_radar_saku

import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.widget.RemoteViews
import android.widget.RemoteViewsService
import org.json.JSONArray
import java.text.NumberFormat
import java.util.Locale

/**
 * RemoteViewsService yang menyediakan data untuk ListView di widget Logged In.
 * Android memanggil [onGetViewFactory] saat ListView membutuhkan data baru.
 */
class RadarSakuWidgetService : RemoteViewsService() {
    override fun onGetViewFactory(intent: Intent): RemoteViewsFactory {
        return RadarSakuWidgetFactory(applicationContext)
    }
}

/**
 * RemoteViewsFactory yang membaca [transactions_json] dari SharedPreferences,
 * mem-parse JSON, dan menyediakan RemoteViews untuk setiap baris transaksi.
 */
private class RadarSakuWidgetFactory(
    private val context: Context,
) : RemoteViewsService.RemoteViewsFactory {

    /** Data transaksi yang di-parse dari JSON */
    private data class TxItem(
        val name: String,
        val amount: Double,
        val categoryName: String,
        val typeAction: String,   // "addition" | "deduction" | "neutral"
    )

    private var transactions: List<TxItem> = emptyList()

    // ─── RemoteViewsFactory lifecycle ───────────────────────────────────────

    override fun onCreate() {}

    override fun onDestroy() {}

    /**
     * Dipanggil oleh Android ketika data perlu di-refresh
     * (setelah [AppWidgetManager.notifyAppWidgetViewDataChanged]).
     */
    override fun onDataSetChanged() {
        val prefs = context.getSharedPreferences("HomeWidgetPlugin", Context.MODE_PRIVATE)
        val json = prefs.getString("transactions_json", "[]") ?: "[]"
        transactions = parseTransactions(json)
    }

    // ─── Data supply ────────────────────────────────────────────────────────

    override fun getCount(): Int = transactions.size

    override fun getViewAt(position: Int): RemoteViews {
        val views = RemoteViews(context.packageName, R.layout.widget_transaction_item)

        if (position >= transactions.size) return views

        val tx = transactions[position]

        // Nama transaksi
        views.setTextViewText(R.id.tv_tx_name, tx.name)

        // Format amount: "Rp 25.000"
        val formatted = formatCurrency(tx.amount)
        val prefix = when (tx.typeAction) {
            "addition"  -> "+"
            "deduction" -> "-"
            else        -> ""
        }
        views.setTextViewText(R.id.tv_tx_amount, "$prefix$formatted")

        // Warna berdasarkan tipe transaksi
        val color = when (tx.typeAction) {
            "addition"  -> Color.parseColor("#22C55E")  // hijau (income)
            "deduction" -> Color.parseColor("#EF4444")  // merah (expense)
            else        -> Color.parseColor("#94A3B8")  // abu (neutral)
        }
        views.setTextColor(R.id.tv_tx_amount, color)
        // Warnai dot indicator menggunakan color filter
        views.setInt(R.id.iv_tx_icon, "setColorFilter", color)

        return views
    }

    override fun getLoadingView(): RemoteViews? = null

    override fun getViewTypeCount(): Int = 1

    override fun getItemId(position: Int): Long = position.toLong()

    override fun hasStableIds(): Boolean = true

    // ─── Helpers ────────────────────────────────────────────────────────────

    private fun parseTransactions(json: String): List<TxItem> {
        val result = mutableListOf<TxItem>()
        try {
            val array = JSONArray(json)
            for (i in 0 until array.length()) {
                val obj = array.getJSONObject(i)
                result.add(
                    TxItem(
                        name         = obj.optString("name", ""),
                        amount       = obj.optString("amount", "0").toDoubleOrNull() ?: 0.0,
                        categoryName = obj.optString("category_name", ""),
                        typeAction   = obj.optString("type_action", "neutral"),
                    )
                )
            }
        } catch (_: Exception) {
            // Abaikan error parse — tampilkan list kosong
        }
        return result
    }

    /**
     * Format angka ke format Rupiah Indonesia tanpa desimal.
     * Contoh: 25000.0 → "Rp 25.000"
     */
    private fun formatCurrency(amount: Double): String {
        val nf = NumberFormat.getNumberInstance(Locale("id", "ID")).apply {
            maximumFractionDigits = 0
        }
        return "Rp ${nf.format(amount.toLong())}"
    }
}
