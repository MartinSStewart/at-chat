module Evergreen.V363.Game exposing (..)

import Array
import Evergreen.V363.Go
import Evergreen.V363.Id
import Evergreen.V363.Message
import Evergreen.V363.SecretId
import Evergreen.V363.SheepGame
import Evergreen.V363.UserSession
import Evergreen.V363.WordSpellingGame
import SeqDict


type Msg
    = GoGameMsg Evergreen.V363.Go.GameMsg
    | GoSetupMsg Evergreen.V363.Go.SetupMsg
    | WordSpellingGameMsg Evergreen.V363.WordSpellingGame.GameMsg
    | WordSpellingSetupMsg Evergreen.V363.WordSpellingGame.SetupMsg
    | SheepGameMsg Evergreen.V363.SheepGame.GameMsg
    | SheepSetupMsg Evergreen.V363.SheepGame.SetupMsg
    | PressedShareMatch (Evergreen.V363.Id.Id Evergreen.V363.Id.ChannelMessageId)
    | PressedCopyLink String
    | SelectedMatch (Evergreen.V363.Id.Id Evergreen.V363.Id.ChannelMessageId)
    | PressedReset
    | PressedSelectGame Evergreen.V363.Message.GameType
    | CheckedSheepGameQuestionsDebounce Int
    | CheckedSheepGameSaveDebounce (Evergreen.V363.Id.Id Evergreen.V363.Id.ChannelMessageId) Evergreen.V363.SheepGame.Input Int
    | NoOpMsg


type FrontendGameData
    = FrontendGameData_Go Evergreen.V363.Go.ValidatedSetup (Array.Array Evergreen.V363.Go.ActionWithTime) Evergreen.V363.Go.Shared
    | FrontendGameData_WordSpellingGame Evergreen.V363.WordSpellingGame.ValidatedSetup (Array.Array Evergreen.V363.WordSpellingGame.ActionWithTime) Evergreen.V363.WordSpellingGame.Shared
    | FrontendGameData_SheepGame Evergreen.V363.SheepGame.ValidatedSetup (Array.Array Evergreen.V363.SheepGame.ActionWithTime) Evergreen.V363.SheepGame.Shared


type MatchData
    = MatchData
        { data : FrontendGameData
        , publicLink : Maybe (Evergreen.V363.SecretId.SecretId Evergreen.V363.Id.GamePublicId)
        }
    | MatchNotLoaded Evergreen.V363.Message.GameType


type BackendGameData
    = GameData_Go Evergreen.V363.Go.ValidatedSetup (Array.Array Evergreen.V363.Go.ActionWithTime)
    | GameData_WordSpellingGame Evergreen.V363.WordSpellingGame.ValidatedSetup (Array.Array Evergreen.V363.WordSpellingGame.ActionWithTime) Evergreen.V363.WordSpellingGame.Shared
    | GameData_SheepGame Evergreen.V363.SheepGame.ValidatedSetup (Array.Array Evergreen.V363.SheepGame.ActionWithTime) Evergreen.V363.SheepGame.Shared


type alias LoadedMatch =
    { gameData : BackendGameData
    , publicLink : Maybe (Evergreen.V363.SecretId.SecretId Evergreen.V363.Id.GamePublicId)
    }


type LocalChange
    = CreatePublicLink (Evergreen.V363.Id.Id Evergreen.V363.Id.ChannelMessageId) (Evergreen.V363.UserSession.ToBeFilledInByBackend (Evergreen.V363.SecretId.SecretId Evergreen.V363.Id.GamePublicId))
    | LoadMatch (Evergreen.V363.Id.Id Evergreen.V363.Id.ChannelMessageId) (Evergreen.V363.UserSession.ToBeFilledInByBackend LoadedMatch)
    | LocalChange_Go (Evergreen.V363.Id.Id Evergreen.V363.Id.ChannelMessageId) Evergreen.V363.Go.LocalChange
    | LocalChange_WordSpellingGame (Evergreen.V363.Id.Id Evergreen.V363.Id.ChannelMessageId) Evergreen.V363.WordSpellingGame.LocalChange
    | LocalChange_SheepGame (Evergreen.V363.Id.Id Evergreen.V363.Id.ChannelMessageId) Evergreen.V363.SheepGame.LocalChange


type Game
    = GoModel_Game Evergreen.V363.Go.GameModel
    | WordSpellingGame_Game Evergreen.V363.WordSpellingGame.GameData
    | SheepGame_Game Evergreen.V363.SheepGame.GameData


type Setup
    = GameSelect
    | GoModel_Setup Evergreen.V363.Go.SetupModel
    | WordSpellingGame_Setup Evergreen.V363.WordSpellingGame.SetupModel
    | SheepGame_Setup Evergreen.V363.SheepGame.SetupModel


type alias Model =
    { startedGames : SeqDict.SeqDict (Evergreen.V363.Id.Id Evergreen.V363.Id.ChannelMessageId) Game
    , setup : Setup
    , sheepGameQuestionsCounter : Int
    , sheepGameSaveCounters : SeqDict.SeqDict ( Evergreen.V363.Id.Id Evergreen.V363.Id.ChannelMessageId, Evergreen.V363.SheepGame.Input ) Int
    }
