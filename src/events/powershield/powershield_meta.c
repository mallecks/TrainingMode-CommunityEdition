#include "../../events.h"
#include "powershield_meta.h"

static EventMatchData Powershield_MatchData = {
    .timer = MATCH_TIMER_COUNTUP,
    .matchType = MATCH_MATCHTYPE_TIME,
    .isDisableMusic = true,
    .hideGo = true,
    .hideReady = true,
    .isCreateHUD = true,
    .isDisablePause = true,
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
    .stage = 32,
    .timerSeconds = 0,
    .timerSubSeconds = 0,
};
EventDesc Powershield = {
    .eventName = "Powershield Training\n",
    .eventDescription = "Powershield Falco's laser!",
    .eventFile = "powershield",
    .CSSType = SLCHRKIND_EVENT,
    .isSelectStage = false,
    .use_savestates = false,
    .disable_hazards = true,
    .force_sopo = false,
    .scoreType = 0,
    .callbackPriority = 3,
    .matchData = &Powershield_MatchData,
    .defaultOSD = 0xFFFFFFFF,
};