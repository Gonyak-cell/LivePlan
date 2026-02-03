package com.liveplan.data.database

import androidx.room.Database
import androidx.room.RoomDatabase
import com.liveplan.data.database.dao.CompletionLogDao
import com.liveplan.data.database.dao.ProjectDao
import com.liveplan.data.database.dao.SectionDao
import com.liveplan.data.database.dao.TagDao
import com.liveplan.data.database.dao.TaskDao
import com.liveplan.data.database.entity.CompletionLogEntity
import com.liveplan.data.database.entity.ProjectEntity
import com.liveplan.data.database.entity.SectionEntity
import com.liveplan.data.database.entity.TagEntity
import com.liveplan.data.database.entity.TaskEntity

/**
 * Room database for LivePlan
 */
@Database(
    entities = [
        ProjectEntity::class,
        TaskEntity::class,
        CompletionLogEntity::class,
        SectionEntity::class,
        TagEntity::class
    ],
    version = 1,
    exportSchema = true
)
abstract class AppDatabase : RoomDatabase() {

    abstract fun projectDao(): ProjectDao
    abstract fun taskDao(): TaskDao
    abstract fun completionLogDao(): CompletionLogDao
    abstract fun sectionDao(): SectionDao
    abstract fun tagDao(): TagDao

    companion object {
        const val DATABASE_NAME = "liveplan.db"
    }
}
