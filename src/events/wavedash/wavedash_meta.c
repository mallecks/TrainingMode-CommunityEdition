#include "../../events.h"
#include "wavedash_meta.h"


// Wavedash Training
static EventMatchData Wavedash_MatchData = {
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
EventDesc Wavedash = {
    .eventName = "Wavedash Training\n",
    .eventDescription = "Practice  your wavedash,\na fundamental movement technique.\n",
    .eventFile = "wavedash",
    .CSSType = SLCHRKIND_EVENT,
    .isSelectStage = true,
    .use_savestates = false,
    .disable_hazards = true,
    .force_sopo = false,
    .scoreType = 0,
    .callbackPriority = 15,
    .matchData = &Wavedash_MatchData,
    .defaultOSD = 0xFFFFFFFF,
};