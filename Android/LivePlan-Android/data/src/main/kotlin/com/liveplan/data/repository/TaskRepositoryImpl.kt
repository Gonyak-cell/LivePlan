package com.liveplan.data.repository

import com.liveplan.core.model.Task
import com.liveplan.core.repository.TaskRepository
import com.liveplan.data.database.dao.TaskDao
import com.liveplan.data.database.entity.TaskEntity
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.catch
import kotlinx.coroutines.flow.map
import javax.inject.Inject

/**
 * Task repository implementation using Room
 */
class TaskRepositoryImpl @Inject constructor(
    private val taskDao: TaskDao
) : TaskRepository {

    override fun getAllTasks(): Flow<List<Task>> {
        return taskDao.getAllTasks()
            .map { entities -> entities.map { it.toDomain() } }
            .catch { emit(emptyList()) } // Fail-safe
    }

    override fun getTasksByProject(projectId: String): Flow<List<Task>> {
        return taskDao.getTasksByProject(projectId)
            .map { entities -> entities.map { it.toDomain() } }
            .catch { emit(emptyList()) } // Fail-safe
    }

    override suspend fun getTaskById(id: String): Task? {
        return taskDao.getTaskById(id)?.toDomain()
    }

    override suspend fun addTask(task: Task) {
        taskDao.insert(TaskEntity.fromDomain(task))
    }

    override suspend fun updateTask(task: Task) {
        taskDao.update(TaskEntity.fromDomain(task))
    }

    override suspend fun deleteTask(id: String) {
        taskDao.deleteById(id)
    }

    override suspend fun getTasksByIds(ids: List<String>): List<Task> {
        return taskDao.getTasksByIds(ids).map { it.toDomain() }
    }
}
