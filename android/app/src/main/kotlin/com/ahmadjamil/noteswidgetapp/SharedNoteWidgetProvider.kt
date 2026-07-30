package com.ahmadjamil.noteswidgetapp

import android.app.ActivityOptions
import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.graphics.BitmapFactory
import android.graphics.Color
import android.net.Uri
import android.os.Build
import android.util.Base64
import android.view.View
import android.widget.RemoteViews
import java.io.File

/**
 * Home-screen widget. Reads data written by the Dart [home_widget] plugin
 * (`HomeWidgetPreferences`) without depending on home_widget's Kotlin
 * classes (those may not compile under AGP 9 + builtInKotlin=false).
 */
class SharedNoteWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
    ) {
        val widgetData = context.getSharedPreferences(PREFERENCES, Context.MODE_PRIVATE)
        updateWidgets(context, appWidgetManager, appWidgetIds, widgetData)
    }

    private fun updateWidgets(
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

        val bgColor = themeColor(widgetData, "widget_bg_color", Color.parseColor("#FFF8F0"))
        val surfaceColor = themeColor(widgetData, "widget_surface_color", Color.parseColor("#F5EDE0"))
        val textPrimary = themeColor(widgetData, "widget_text_primary_color", Color.parseColor("#3E2723"))
        val textSecondary = themeColor(widgetData, "widget_text_secondary_color", Color.parseColor("#6D4C41"))

        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.shared_note_widget_layout).apply {
                setInt(R.id.widget_container, "setBackgroundColor", bgColor)
                setInt(R.id.widget_logo, "setBackgroundColor", surfaceColor)
                setInt(R.id.widget_friend_label, "setBackgroundColor", surfaceColor)
                setTextColor(R.id.widget_title, textPrimary)
                setTextColor(R.id.widget_body, textSecondary)
                setTextColor(R.id.widget_friend_label, textSecondary)

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

                val uri = if (!noteId.isNullOrEmpty()) {
                    Uri.parse(
                        "noteswidgetapp://shared-note?noteId=${Uri.encode(noteId)}&friend=${Uri.encode(friendLabel)}",
                    )
                } else {
                    null
                }
                setOnClickPendingIntent(
                    R.id.widget_container,
                    launchActivityPendingIntent(context, uri),
                )
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }

    private fun launchActivityPendingIntent(context: Context, uri: Uri?): PendingIntent {
        val intent = Intent(context, MainActivity::class.java).apply {
            action = HOME_WIDGET_LAUNCH_ACTION
            data = uri
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }

        var flags = PendingIntent.FLAG_UPDATE_CURRENT
        if (Build.VERSION.SDK_INT >= 23) {
            flags = flags or PendingIntent.FLAG_IMMUTABLE
        }

        if (Build.VERSION.SDK_INT < 34) {
            return PendingIntent.getActivity(context, 0, intent, flags)
        }

        val options = ActivityOptions.makeBasic()
        if (Build.VERSION.SDK_INT >= 35) {
            options.setPendingIntentCreatorBackgroundActivityStartMode(
                ActivityOptions.MODE_BACKGROUND_ACTIVITY_START_ALLOWED,
            )
        } else {
            @Suppress("DEPRECATION")
            options.pendingIntentBackgroundActivityStartMode =
                ActivityOptions.MODE_BACKGROUND_ACTIVITY_START_ALLOWED
        }

        return PendingIntent.getActivity(context, 0, intent, flags, options.toBundle())
    }

    private fun themeColor(
        prefs: SharedPreferences,
        key: String,
        fallback: Int,
    ): Int = prefs.getString(key, null)?.toIntOrNull() ?: fallback

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

    companion object {
        /** Must match home_widget's SharedPreferences name. */
        private const val PREFERENCES = "HomeWidgetPreferences"

        /** Must match home_widget's launch action for deep links. */
        private const val HOME_WIDGET_LAUNCH_ACTION = "es.antonborri.home_widget.action.LAUNCH"
    }
}
