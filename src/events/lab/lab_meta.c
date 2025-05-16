#include "../../events.h"
#include "lab_meta.h"

static EventMatchData Lab_MatchData = {
    .timer = MATCH_TIMER_COUNTUP,
    .matchType = MATCH_MATCHTYPE_TIME,
    .isDisableMusic = false,
    .hideGo = true,
    .hideReady = true,
    .isCreateHUD = true,
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
EventDesc Lab = {
    // Event Name
    .eventName = "Training Lab\n",
    .eventDescription = "Free practice with\ncomplete control.\n",
    .eventFile = "lab",
    .jumpTableIndex = -1,
    .eventCSSFile = "TM/labCSS.dat",
    .CSSType = SLCHRKIND_TRAINING,
    .CSSList = NULL,
    .isSelectStage = true,
    .use_savestates = false,
    .disable_hazards = true,
    .force_sopo = false,
    .scoreType = SCORETYPE_KO,
    .callbackPriority = 3,
    .matchData = &Lab_MatchData,
    .defaultOSD = 0xFFFFFFFF,
};
