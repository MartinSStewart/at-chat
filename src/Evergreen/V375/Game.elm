module Evergreen.V375.Game exposing (..)

import Array
import Evergreen.V375.Go
import Evergreen.V375.Id
import Evergreen.V375.Message
import Evergreen.V375.SecretId
import Evergreen.V375.SheepGame
import Evergreen.V375.UserSession
import Evergreen.V375.WordSpellingGame
import SeqDict


type Msg
    = GoGameMsg Evergreen.V375.Go.GameMsg
    | GoSetupMsg Evergreen.V375.Go.SetupMsg
    | WordSpellingGameMsg Evergreen.V375.WordSpellingGame.GameMsg
    | WordSpellingSetupMsg Evergreen.V375.WordSpellingGame.SetupMsg
    | SheepGameMsg Evergreen.V375.SheepGame.GameMsg
    | SheepSetupMsg Evergreen.V375.SheepGame.SetupMsg
    | PressedShareMatch (Evergreen.V375.Id.Id Evergreen.V375.Id.ChannelMessageId)
    | PressedCopyLink String
    | SelectedMatch (Evergreen.V375.Id.Id Evergreen.V375.Id.ChannelMessageId)
    | PressedReset
    | PressedSelectGame Evergreen.V375.Message.GameType
    | CheckedSheepGameQuestionsDebounce Int
    | CheckedSheepGameSaveDebounce (Evergreen.V375.Id.Id Evergreen.V375.Id.ChannelMessageId) Evergreen.V375.SheepGame.Input Int
    | NoOpMsg


type FrontendGameData
    = FrontendGameData_Go Evergreen.V375.Go.ValidatedSetup (Array.Array Evergreen.V375.Go.ActionWithTime) Evergreen.V375.Go.Shared
    | FrontendGameData_WordSpellingGame Evergreen.V375.WordSpellingGame.ValidatedSetup (Array.Array Evergreen.V375.WordSpellingGame.ActionWithTime) Evergreen.V375.WordSpellingGame.Shared
    | FrontendGameData_SheepGame Evergreen.V375.SheepGame.ValidatedSetup (Array.Array Evergreen.V375.SheepGame.ActionWithTime) Evergreen.V375.SheepGame.Shared


type MatchData
    = MatchData
        { data : FrontendGameData
        , publicLink : Maybe (Evergreen.V375.SecretId.SecretId Evergreen.V375.Id.GamePublicId)
        }
    | MatchNotLoaded Evergreen.V375.Message.GameType


type BackendGameData
    = GameData_Go Evergreen.V375.Go.ValidatedSetup (Array.Array Evergreen.V375.Go.ActionWithTime)
    | GameData_WordSpellingGame Evergreen.V375.WordSpellingGame.ValidatedSetup (Array.Array Evergreen.V375.WordSpellingGame.ActionWithTime) Evergreen.V375.WordSpellingGame.Shared
    | GameData_SheepGame Evergreen.V375.SheepGame.ValidatedSetup (Array.Array Evergreen.V375.SheepGame.ActionWithTime) Evergreen.V375.SheepGame.Shared


type alias LoadedMatch =
    { gameData : BackendGameData
    , publicLink : Maybe (Evergreen.V375.SecretId.SecretId Evergreen.V375.Id.GamePublicId)
    }


type LocalChange
    = CreatePublicLink (Evergreen.V375.Id.Id Evergreen.V375.Id.ChannelMessageId) (Evergreen.V375.UserSession.ToBeFilledInByBackend (Evergreen.V375.SecretId.SecretId Evergreen.V375.Id.GamePublicId))
    | LoadMatch (Evergreen.V375.Id.Id Evergreen.V375.Id.ChannelMessageId) (Evergreen.V375.UserSession.ToBeFilledInByBackend LoadedMatch)
    | LocalChange_Go (Evergreen.V375.Id.Id Evergreen.V375.Id.ChannelMessageId) Evergreen.V375.Go.LocalChange
    | LocalChange_WordSpellingGame (Evergreen.V375.Id.Id Evergreen.V375.Id.ChannelMessageId) Evergreen.V375.WordSpellingGame.LocalChange
    | LocalChange_SheepGame (Evergreen.V375.Id.Id Evergreen.V375.Id.ChannelMessageId) Evergreen.V375.SheepGame.LocalChange


type Game
    = GoModel_Game Evergreen.V375.Go.GameModel
    | WordSpellingGame_Game Evergreen.V375.WordSpellingGame.GameData
    | SheepGame_Game Evergreen.V375.SheepGame.GameData


type Setup
    = GameSelect
    | GoModel_Setup Evergreen.V375.Go.SetupModel
    | WordSpellingGame_Setup Evergreen.V375.WordSpellingGame.SetupModel
    | SheepGame_Setup Evergreen.V375.SheepGame.SetupModel


type alias Model =
    { startedGames : SeqDict.SeqDict (Evergreen.V375.Id.Id Evergreen.V375.Id.ChannelMessageId) Game
    , setup : Setup
    , sheepGameQuestionsCounter : Int
    , sheepGameSaveCounters : SeqDict.SeqDict ( Evergreen.V375.Id.Id Evergreen.V375.Id.ChannelMessageId, Evergreen.V375.SheepGame.Input ) Int
    }
