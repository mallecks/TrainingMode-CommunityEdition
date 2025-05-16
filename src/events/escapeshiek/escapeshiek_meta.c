#include "../../events.h"

static const EventCharList EscapeSheik_EventCharList = {
    .values = {
        [YOSHI] = 1,
        [CAPTAIN_FALCON] = 1,
        [FALCO] = 1,
        [FOX] = 1,
        [PIKACHU] = 1
    }
};

static EventMatchData EscapeSheik_MatchData = {
    .timer = MATCH_TIMER_COUNTUP,
    .matchType = MATCH_MATCHTYPE_TIME,
    .isDisableMusic = true,
    .hideGo = true,
    .hideReady = true,
    .isCreateHUD = true,
    .isDisablePause = false,
    .timerRunOnPause = false,
    .isHidePauseHUD = true,
    .isShowLRAStart = true,
    .isCheckForLRAStart = true,
    .isShowZRetry = true,
    .isCheckForZRetry = true,
    .isShowAnalogStick = true,
    .isShowScore = false,

    .isRunStockLogic = false,
    .isDisableHit = false,
    .useKOCounter = false,
    .playerKind = -1,
    .cpuKind = 19,
    .stage = 32,
    .timerSeconds = 0,
    .timerSubSeconds = 0,
};
EventDesc EscapeSheik = {
    .eventName = "Escape Sheik Techchase\n",
    .eventDescription = "Practice escaping the tech chase with a\nframe perfect shine or jab SDI!\n",
    .eventFile = 0,
    .jumpTableIndex = 4,
    .CSSType = SLCHRKIND_EVENT,
    .CSSList = &EscapeSheik_EventCharList,
    .isSelectStage = false,
    .use_savestates = false,
    .disable_hazards = true,
    .force_sopo = false,
    .scoreType = SCORETYPE_KO,
    .callbackPriority = 3,
    .matchData = &EscapeSheik_MatchData,
    .defaultOSD = 0xFFFFFFFF,
};