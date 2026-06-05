extends RefCounted
class_name MissionIds

# Shared mission id constants.
# Keep TASK TEST / mission_10 compatibility values in one place.
# This file must not contain mission content or runtime state.

const TASK_TEST_LAYOUT_ID: String = "task_test"
const TASK_TEST_COMPAT_MISSION_ID: String = "mission_10"
const TASK_TEST_INDEX: int = 10

const LEGACY_STORY_MISSION_MIN_INDEX: int = 1
const LEGACY_STORY_MISSION_MAX_INDEX: int = 9
const RETIRED_LEGACY_MISSION_INDEXES: Array[int] = [7, 8]

static func is_task_test_id(mission_id: String) -> bool:
	var normalized_id: String = str(mission_id).strip_edges()
	return normalized_id == TASK_TEST_LAYOUT_ID or normalized_id == TASK_TEST_COMPAT_MISSION_ID

static func resolve_task_test_alias(mission_id: String) -> String:
	return TASK_TEST_LAYOUT_ID if is_task_test_id(mission_id) else str(mission_id).strip_edges()

static func get_task_test_aliases() -> Array[String]:
	return [TASK_TEST_LAYOUT_ID, TASK_TEST_COMPAT_MISSION_ID]

static func is_retired_legacy_mission_index(mission_index: int) -> bool:
	return RETIRED_LEGACY_MISSION_INDEXES.has(mission_index)

static func is_legacy_story_mission_index(mission_index: int) -> bool:
	return mission_index >= LEGACY_STORY_MISSION_MIN_INDEX and mission_index <= LEGACY_STORY_MISSION_MAX_INDEX and not is_retired_legacy_mission_index(mission_index)
