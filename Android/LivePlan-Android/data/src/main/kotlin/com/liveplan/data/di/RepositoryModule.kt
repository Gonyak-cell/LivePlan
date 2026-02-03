package com.liveplan.data.di

import com.liveplan.core.repository.CompletionLogRepository
import com.liveplan.core.repository.ProjectRepository
import com.liveplan.core.repository.SavedViewRepository
import com.liveplan.core.repository.SectionRepository
import com.liveplan.core.repository.TagRepository
import com.liveplan.core.repository.TaskRepository
import com.liveplan.data.repository.CompletionLogRepositoryImpl
import com.liveplan.data.repository.ProjectRepositoryImpl
import com.liveplan.data.repository.SavedViewRepositoryImpl
import com.liveplan.data.repository.SectionRepositoryImpl
import com.liveplan.data.repository.TagRepositoryImpl
import com.liveplan.data.repository.TaskRepositoryImpl
import dagger.Binds
import dagger.Module
import dagger.hilt.InstallIn
import dagger.hilt.components.SingletonComponent
import javax.inject.Singleton

@Module
@InstallIn(SingletonComponent::class)
abstract class RepositoryModule {

    @Binds
    @Singleton
    abstract fun bindProjectRepository(impl: ProjectRepositoryImpl): ProjectRepository

    @Binds
    @Singleton
    abstract fun bindTaskRepository(impl: TaskRepositoryImpl): TaskRepository

    @Binds
    @Singleton
    abstract fun bindCompletionLogRepository(impl: CompletionLogRepositoryImpl): CompletionLogRepository

    @Binds
    @Singleton
    abstract fun bindSectionRepository(impl: SectionRepositoryImpl): SectionRepository

    @Binds
    @Singleton
    abstract fun bindTagRepository(impl: TagRepositoryImpl): TagRepository

    @Binds
    @Singleton
    abstract fun bindSavedViewRepository(impl: SavedViewRepositoryImpl): SavedViewRepository
}
