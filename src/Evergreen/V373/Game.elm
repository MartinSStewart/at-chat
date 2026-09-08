module Evergreen.V373.Game exposing (..)

import Array
import Evergreen.V373.Go
import Evergreen.V373.Id
import Evergreen.V373.Message
import Evergreen.V373.SecretId
import Evergreen.V373.SheepGame
import Evergreen.V373.UserSession
import Evergreen.V373.WordSpellingGame
import SeqDict


type Msg
    = GoGameMsg Evergreen.V373.Go.GameMsg
    | GoSetupMsg Evergreen.V373.Go.SetupMsg
    | WordSpellingGameMsg Evergreen.V373.WordSpellingGame.GameMsg
    | WordSpellingSetupMsg Evergreen.V373.WordSpellingGame.SetupMsg
    | SheepGameMsg Evergreen.V373.SheepGame.GameMsg
    | SheepSetupMsg Evergreen.V373.SheepGame.SetupMsg
    | PressedShareMatch (Evergreen.V373.Id.Id Evergreen.V373.Id.ChannelMessageId)
    | PressedCopyLink String
    | SelectedMatch (Evergreen.V373.Id.Id Evergreen.V373.Id.ChannelMessageId)
    | PressedReset
    | PressedSelectGame Evergreen.V373.Message.GameType
    | CheckedSheepGameQuestionsDebounce Int
    | CheckedSheepGameSaveDebounce (Evergreen.V373.Id.Id Evergreen.V373.Id.ChannelMessageId) Evergreen.V373.SheepGame.Input Int
    | NoOpMsg


type FrontendGameData
    = FrontendGameData_Go Evergreen.V373.Go.ValidatedSetup (Array.Array Evergreen.V373.Go.ActionWithTime) Evergreen.V373.Go.Shared
    | FrontendGameData_WordSpellingGame Evergreen.V373.WordSpellingGame.ValidatedSetup (Array.Array Evergreen.V373.WordSpellingGame.ActionWithTime) Evergreen.V373.WordSpellingGame.Shared
    | FrontendGameData_SheepGame Evergreen.V373.SheepGame.ValidatedSetup (Array.Array Evergreen.V373.SheepGame.ActionWithTime) Evergreen.V373.SheepGame.Shared


type MatchData
    = MatchData
        { data : FrontendGameData
        , publicLink : Maybe (Evergreen.V373.SecretId.SecretId Evergreen.V373.Id.GamePublicId)
        }
    | MatchNotLoaded Evergreen.V373.Message.GameType


type BackendGameData
    = GameData_Go Evergreen.V373.Go.ValidatedSetup (Array.Array Evergreen.V373.Go.ActionWithTime)
    | GameData_WordSpellingGame Evergreen.V373.WordSpellingGame.ValidatedSetup (Array.Array Evergreen.V373.WordSpellingGame.ActionWithTime) Evergreen.V373.WordSpellingGame.Shared
    | GameData_SheepGame Evergreen.V373.SheepGame.ValidatedSetup (Array.Array Evergreen.V373.SheepGame.ActionWithTime) Evergreen.V373.SheepGame.Shared


type alias LoadedMatch =
    { gameData : BackendGameData
    , publicLink : Maybe (Evergreen.V373.SecretId.SecretId Evergreen.V373.Id.GamePublicId)
    }


type LocalChange
    = CreatePublicLink (Evergreen.V373.Id.Id Evergreen.V373.Id.ChannelMessageId) (Evergreen.V373.UserSession.ToBeFilledInByBackend (Evergreen.V373.SecretId.SecretId Evergreen.V373.Id.GamePublicId))
    | LoadMatch (Evergreen.V373.Id.Id Evergreen.V373.Id.ChannelMessageId) (Evergreen.V373.UserSession.ToBeFilledInByBackend LoadedMatch)
    | LocalChange_Go (Evergreen.V373.Id.Id Evergreen.V373.Id.ChannelMessageId) Evergreen.V373.Go.LocalChange
    | LocalChange_WordSpellingGame (Evergreen.V373.Id.Id Evergreen.V373.Id.ChannelMessageId) Evergreen.V373.WordSpellingGame.LocalChange
    | LocalChange_SheepGame (Evergreen.V373.Id.Id Evergreen.V373.Id.ChannelMessageId) Evergreen.V373.SheepGame.LocalChange


type Game
    = GoModel_Game Evergreen.V373.Go.GameModel
    | WordSpellingGame_Game Evergreen.V373.WordSpellingGame.GameData
    | SheepGame_Game Evergreen.V373.SheepGame.GameData


type Setup
    = GameSelect
    | GoModel_Setup Evergreen.V373.Go.SetupModel
    | WordSpellingGame_Setup Evergreen.V373.WordSpellingGame.SetupModel
    | SheepGame_Setup Evergreen.V373.SheepGame.SetupModel


type alias Model =
    { startedGames : SeqDict.SeqDict (Evergreen.V373.Id.Id Evergreen.V373.Id.ChannelMessageId) Game
    , setup : Setup
    , sheepGameQuestionsCounter : Int
    , sheepGameSaveCounters : SeqDict.SeqDict ( Evergreen.V373.Id.Id Evergreen.V373.Id.ChannelMessageId, Evergreen.V373.SheepGame.Input ) Int
    }
