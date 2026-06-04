package com.ahmadjamil.noteswidgetapp

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.net.Uri
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

class SharedNoteWidgetProvider : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        val title = widgetData.getString("shared_note_title", null) ?: "Notes Widget"
        val body = widgetData.getString("shared_note_body", null)
            ?: "Add a friend to see your shared note"
        val noteId = widgetData.getString("active_shared_note_id", null)
        val friendLabel = widgetData.getString("active_friend_label", null) ?: "Shared note"

        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.shared_note_widget_layout).apply {
                setTextViewText(R.id.widget_title, title)
                setTextViewText(R.id.widget_body, body)

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
}
