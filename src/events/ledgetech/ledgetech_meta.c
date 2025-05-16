#include "../../events.h"

static const EventCharList Ledgetech_EventCharList = {
    .values = {
        [FALCO] = 1,
        [FOX] = 1
    }
};

static EventMatchData Ledgetech_MatchData = {
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
    .cpuKind = 20,
    .stage = -1,
    .timerSeconds = 0,
    .timerSubSeconds = 0,
};
EventDesc Ledgetech = {
    .eventName = "Ledge-Tech Training\n",
    .eventDescription = "Practice ledge-teching\nFalco's down-smash!",
    .eventFile = 0,
    .jumpTableIndex = 7,
    .CSSType = SLCHRKIND_EVENT,
    .CSSList = &Ledgetech_EventCharList,
    .isSelectStage = true,
    .use_savestates = false,
    .disable_hazards = true,
    .force_sopo = false,
    .scoreType = SCORETYPE_KO,
    .callbackPriority = 3,
    .matchData = &Ledgetech_MatchData,
    .defaultOSD = 0xFFFFFFFF,
};
