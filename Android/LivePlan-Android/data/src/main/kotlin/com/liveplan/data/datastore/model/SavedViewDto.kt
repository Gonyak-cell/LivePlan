package com.liveplan.data.datastore.model

import com.liveplan.core.model.DueRange
import com.liveplan.core.model.FilterDefinition
import com.liveplan.core.model.Priority
import com.liveplan.core.model.SavedView
import com.liveplan.core.model.ViewScope
import com.liveplan.core.model.ViewType
import com.liveplan.core.model.WorkflowState
import kotlinx.serialization.Serializable

/**
 * Serializable DTO for SavedView
 * Used for DataStore persistence
 */
@Serializable
data class SavedViewDto(
    val id: String,
    val name: String,
    val scopeType: String, // "global" or "project"
    val scopeProjectId: String? = null, // only for project scope
    val viewType: String,
    val definition: FilterDefinitionDto,
    val createdAt: Long,
    val updatedAt: Long
) {
    fun toDomain(): SavedView = SavedView(
        id = id,
        name = name,
        scope = when (scopeType) {
            "project" -> ViewScope.Project(scopeProjectId ?: "")
            else -> ViewScope.Global
        },
        viewType = try { ViewType.valueOf(viewType) } catch (e: Exception) { ViewType.LIST },
        definition = definition.toDomain(),
        createdAt = createdAt,
        updatedAt = updatedAt
    )

    companion object {
        fun fromDomain(savedView: SavedView): SavedViewDto = SavedViewDto(
            id = savedView.id,
            name = savedView.name,
            scopeType = when (savedView.scope) {
                is ViewScope.Global -> "global"
                is ViewScope.Project -> "project"
            },
            scopeProjectId = (savedView.scope as? ViewScope.Project)?.projectId,
            viewType = savedView.viewType.name,
            definition = FilterDefinitionDto.fromDomain(savedView.definition),
            createdAt = savedView.createdAt,
            updatedAt = savedView.updatedAt
        )
    }
}

/**
 * Serializable DTO for FilterDefinition
 */
@Serializable
data class FilterDefinitionDto(
    val includeProjects: List<String>? = null,
    val includeTags: List<String>? = null,
    val includeSections: List<String>? = null,
    val priorityAtMost: String? = null,
    val priorityAtLeast: String? = null,
    val stateIn: List<String> = listOf("TODO", "DOING"),
    val dueRange: String = "NONE",
    val includeRecurring: Boolean = true,
    val excludeBlocked: Boolean = true
) {
    fun toDomain(): FilterDefinition = FilterDefinition(
        includeProjects = includeProjects,
        includeTags = includeTags,
        includeSections = includeSections,
        priorityAtMost = priorityAtMost?.let {
            try { Priority.valueOf(it) } catch (e: Exception) { null }
        },
        priorityAtLeast = priorityAtLeast?.let {
            try { Priority.valueOf(it) } catch (e: Exception) { null }
        },
        stateIn = stateIn.mapNotNull {
            try { WorkflowState.valueOf(it) } catch (e: Exception) { null }
        }.toSet().ifEmpty { setOf(WorkflowState.TODO, WorkflowState.DOING) },
        dueRange = try { DueRange.valueOf(dueRange) } catch (e: Exception) { DueRange.NONE },
        includeRecurring = includeRecurring,
        excludeBlocked = excludeBlocked
    )

    companion object {
        fun fromDomain(filter: FilterDefinition): FilterDefinitionDto = FilterDefinitionDto(
            includeProjects = filter.includeProjects,
            includeTags = filter.includeTags,
            includeSections = filter.includeSections,
            priorityAtMost = filter.priorityAtMost?.name,
            priorityAtLeast = filter.priorityAtLeast?.name,
            stateIn = filter.stateIn.map { it.name },
            dueRange = filter.dueRange.name,
            includeRecurring = filter.includeRecurring,
            excludeBlocked = filter.excludeBlocked
        )
    }
}

/**
 * Wrapper for list of SavedViewDto
 */
@Serializable
data class SavedViewListDto(
    val views: List<SavedViewDto> = emptyList()
)
