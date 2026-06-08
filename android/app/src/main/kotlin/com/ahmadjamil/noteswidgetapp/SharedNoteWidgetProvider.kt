package com.ahmadjamil.noteswidgetapp

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.graphics.BitmapFactory
import android.net.Uri
import android.util.Base64
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider
import java.io.File

class SharedNoteWidgetProvider : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        val title = widgetData.getString("shared_note_title", null) ?: "SyncNotes"
        val body = widgetData.getString("shared_note_body", null)
            ?: "Add a friend to see your shared note"
        val noteId = widgetData.getString("active_shared_note_id", null)
        val friendLabel = widgetData.getString("active_friend_label", null) ?: "Shared note"
        val noteType = widgetData.getString("shared_note_type", "text") ?: "text"
        val drawingBase64 = widgetData.getString("shared_note_drawing_base64", null)
        val drawingImagePath = widgetData.getString("shared_note_drawing_image", null)

        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.shared_note_widget_layout).apply {
                if (noteType == "drawing") {
                    setViewVisibility(R.id.widget_title, View.GONE)
                    setViewVisibility(R.id.widget_body, View.GONE)

                    val bitmap = loadDrawingBitmap(drawingBase64, drawingImagePath)
                    if (bitmap != null) {
                        setImageViewBitmap(R.id.widget_drawing_preview, bitmap)
                        setViewVisibility(R.id.widget_drawing_preview, View.VISIBLE)
                    } else {
                        setViewVisibility(R.id.widget_drawing_preview, View.GONE)
                        setViewVisibility(R.id.widget_body, View.VISIBLE)
                        setTextViewText(
                            R.id.widget_body,
                            "Handwritten note — tap to open",
                        )
                    }
                } else {
                    setViewVisibility(R.id.widget_drawing_preview, View.GONE)
                    setViewVisibility(R.id.widget_title, View.VISIBLE)
                    setViewVisibility(R.id.widget_body, View.VISIBLE)
                    setTextViewText(R.id.widget_title, title)
                    setTextViewText(R.id.widget_body, body)
                }

                if (!noteId.isNullOrEmpty() && friendLabel.isNotBlank()) {
                    setTextViewText(R.id.widget_friend_label, "WITH $friendLabel")
                    setViewVisibility(R.id.widget_friend_label, View.VISIBLE)
                } else {
                    setViewVisibility(R.id.widget_friend_label, View.GONE)
                }

                val launchIntent = if (!noteId.isNullOrEmpty()) {
                    val uri = Uri.parse(
                        "noteswidgetapp://shared-note?noteId=${Uri.encode(noteId)}&friend=${Uri.encode(friendLabel)}",
                    )
                    HomeWidgetLaunchIntent.getActivity(
                        context,
                        MainActivity::class.java,
                        uri,
                    )
                } else {
                    HomeWidgetLaunchIntent.getActivity(
                        context,
                        MainActivity::class.java,
                    )
                }
                setOnClickPendingIntent(R.id.widget_container, launchIntent)
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }

    private fun loadDrawingBitmap(base64: String?, path: String?): android.graphics.Bitmap? {
        if (!base64.isNullOrEmpty()) {
            try {
                val bytes = Base64.decode(base64, Base64.DEFAULT)
                val bitmap = BitmapFactory.decodeByteArray(bytes, 0, bytes.size)
                if (bitmap != null) return bitmap
            } catch (_: Exception) {
            }
        }

        if (path.isNullOrEmpty()) return null
        val file = File(path)
        if (!file.exists() || !file.canRead()) return null
        return try {
            BitmapFactory.decodeFile(file.absolutePath)
        } catch (_: Exception) {
            null
        }
    }
}
