package com.liveplan.core.model

/**
 * Task workflow state for board/kanban view
 * Aligned with iOS AppCore WorkflowState enum
 */
enum class WorkflowState {
    TODO,
    DOING,
    DONE;

    companion object {
        val DEFAULT = TODO
    }

    val isActive: Boolean
        get() = this != DONE
}
