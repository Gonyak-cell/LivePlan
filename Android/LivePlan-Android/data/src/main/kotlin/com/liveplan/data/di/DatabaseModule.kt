package com.liveplan.data.di

import android.content.Context
import androidx.room.Room
import com.liveplan.data.database.AppDatabase
import com.liveplan.data.database.dao.CompletionLogDao
import com.liveplan.data.database.dao.ProjectDao
import com.liveplan.data.database.dao.SectionDao
import com.liveplan.data.database.dao.TagDao
import com.liveplan.data.database.dao.TaskDao
import com.liveplan.data.database.migration.Migrations
import dagger.Module
import dagger.Provides
import dagger.hilt.InstallIn
import dagger.hilt.android.qualifiers.ApplicationContext
import dagger.hilt.components.SingletonComponent
import javax.inject.Singleton

@Module
@InstallIn(SingletonComponent::class)
object DatabaseModule {

    @Provides
    @Singleton
    fun provideDatabase(@ApplicationContext context: Context): AppDatabase {
        return Room.databaseBuilder(
            context,
            AppDatabase::class.java,
            AppDatabase.DATABASE_NAME
        )
            .addMigrations(*Migrations.ALL)
            .fallbackToDestructiveMigration() // Fail-safe: recreate DB if migration fails
            .build()
    }

    @Provides
    fun provideProjectDao(database: AppDatabase): ProjectDao = database.projectDao()

    @Provides
    fun provideTaskDao(database: AppDatabase): TaskDao = database.taskDao()

    @Provides
    fun provideCompletionLogDao(database: AppDatabase): CompletionLogDao = database.completionLogDao()

    @Provides
    fun provideSectionDao(database: AppDatabase): SectionDao = database.sectionDao()

    @Provides
    fun provideTagDao(database: AppDatabase): TagDao = database.tagDao()
}
