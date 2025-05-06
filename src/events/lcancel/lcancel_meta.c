#include "../../events.h"
#include "lcancel_meta.h"


static EventMatchData LCancel_MatchData = {
    .timer = MATCH_TIMER_HIDE,
    .matchType = MATCH_MATCHTYPE_TIME,
    .isDisableMusic = false,
    .hideGo = true,
    .hideReady = true,
    .isCreateHUD = false,
    .isDisablePause = true,
    .timerRunOnPause = false,
    .isHidePauseHUD = true,
    .isShowLRAStart = true,
    .isCheckForLRAStart = true,
    .isShowZRetry = false,
    .isCheckForZRetry = false,
    .isShowAnalogStick = true,
    .isShowScore = false,

    .isRunStockLogic = false,
    .isDisableHit = false,
    .useKOCounter = false,
    .playerKind = -1,
    .cpuKind = -1,
    .stage = -1,
    .timerSeconds = 0,
    .timerSubSeconds = 0,
};
EventDesc LCancel = {
    // Event Name
    .eventName = "L-Cancel Training\n",
    .eventDescription = "Practice L-Cancelling on\na stationary CPU.\n",
    .eventFile = "lcancel",
    .jumpTableIndex = -1,
    .CSSType = SLCHRKIND_EVENT,
    .isSelectStage = true,
    .use_savestates = false,
    .disable_hazards = true,
    .force_sopo = false,
    .scoreType = SCORETYPE_KO,
    .callbackPriority = 15,
    .matchData = &LCancel_MatchData,
    .defaultOSD = 0xFFFFFFFF,
};