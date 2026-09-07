module Evergreen.V370.Game exposing (..)

import Array
import Evergreen.V370.Go
import Evergreen.V370.Id
import Evergreen.V370.Message
import Evergreen.V370.SecretId
import Evergreen.V370.SheepGame
import Evergreen.V370.UserSession
import Evergreen.V370.WordSpellingGame
import SeqDict


type Msg
    = GoGameMsg Evergreen.V370.Go.GameMsg
    | GoSetupMsg Evergreen.V370.Go.SetupMsg
    | WordSpellingGameMsg Evergreen.V370.WordSpellingGame.GameMsg
    | WordSpellingSetupMsg Evergreen.V370.WordSpellingGame.SetupMsg
    | SheepGameMsg Evergreen.V370.SheepGame.GameMsg
    | SheepSetupMsg Evergreen.V370.SheepGame.SetupMsg
    | PressedShareMatch (Evergreen.V370.Id.Id Evergreen.V370.Id.ChannelMessageId)
    | PressedCopyLink String
    | SelectedMatch (Evergreen.V370.Id.Id Evergreen.V370.Id.ChannelMessageId)
    | PressedReset
    | PressedSelectGame Evergreen.V370.Message.GameType
    | CheckedSheepGameQuestionsDebounce Int
    | CheckedSheepGameSaveDebounce (Evergreen.V370.Id.Id Evergreen.V370.Id.ChannelMessageId) Evergreen.V370.SheepGame.Input Int
    | NoOpMsg


type FrontendGameData
    = FrontendGameData_Go Evergreen.V370.Go.ValidatedSetup (Array.Array Evergreen.V370.Go.ActionWithTime) Evergreen.V370.Go.Shared
    | FrontendGameData_WordSpellingGame Evergreen.V370.WordSpellingGame.ValidatedSetup (Array.Array Evergreen.V370.WordSpellingGame.ActionWithTime) Evergreen.V370.WordSpellingGame.Shared
    | FrontendGameData_SheepGame Evergreen.V370.SheepGame.ValidatedSetup (Array.Array Evergreen.V370.SheepGame.ActionWithTime) Evergreen.V370.SheepGame.Shared


type MatchData
    = MatchData
        { data : FrontendGameData
        , publicLink : Maybe (Evergreen.V370.SecretId.SecretId Evergreen.V370.Id.GamePublicId)
        }
    | MatchNotLoaded Evergreen.V370.Message.GameType


type BackendGameData
    = GameData_Go Evergreen.V370.Go.ValidatedSetup (Array.Array Evergreen.V370.Go.ActionWithTime)
    | GameData_WordSpellingGame Evergreen.V370.WordSpellingGame.ValidatedSetup (Array.Array Evergreen.V370.WordSpellingGame.ActionWithTime) Evergreen.V370.WordSpellingGame.Shared
    | GameData_SheepGame Evergreen.V370.SheepGame.ValidatedSetup (Array.Array Evergreen.V370.SheepGame.ActionWithTime) Evergreen.V370.SheepGame.Shared


type alias LoadedMatch =
    { gameData : BackendGameData
    , publicLink : Maybe (Evergreen.V370.SecretId.SecretId Evergreen.V370.Id.GamePublicId)
    }


type LocalChange
    = CreatePublicLink (Evergreen.V370.Id.Id Evergreen.V370.Id.ChannelMessageId) (Evergreen.V370.UserSession.ToBeFilledInByBackend (Evergreen.V370.SecretId.SecretId Evergreen.V370.Id.GamePublicId))
    | LoadMatch (Evergreen.V370.Id.Id Evergreen.V370.Id.ChannelMessageId) (Evergreen.V370.UserSession.ToBeFilledInByBackend LoadedMatch)
    | LocalChange_Go (Evergreen.V370.Id.Id Evergreen.V370.Id.ChannelMessageId) Evergreen.V370.Go.LocalChange
    | LocalChange_WordSpellingGame (Evergreen.V370.Id.Id Evergreen.V370.Id.ChannelMessageId) Evergreen.V370.WordSpellingGame.LocalChange
    | LocalChange_SheepGame (Evergreen.V370.Id.Id Evergreen.V370.Id.ChannelMessageId) Evergreen.V370.SheepGame.LocalChange


type Game
    = GoModel_Game Evergreen.V370.Go.GameModel
    | WordSpellingGame_Game Evergreen.V370.WordSpellingGame.GameData
    | SheepGame_Game Evergreen.V370.SheepGame.GameData


type Setup
    = GameSelect
    | GoModel_Setup Evergreen.V370.Go.SetupModel
    | WordSpellingGame_Setup Evergreen.V370.WordSpellingGame.SetupModel
    | SheepGame_Setup Evergreen.V370.SheepGame.SetupModel


type alias Model =
    { startedGames : SeqDict.SeqDict (Evergreen.V370.Id.Id Evergreen.V370.Id.ChannelMessageId) Game
    , setup : Setup
    , sheepGameQuestionsCounter : Int
    , sheepGameSaveCounters : SeqDict.SeqDict ( Evergreen.V370.Id.Id Evergreen.V370.Id.ChannelMessageId, Evergreen.V370.SheepGame.Input ) Int
    }
