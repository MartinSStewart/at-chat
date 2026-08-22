module Evergreen.V360.Game exposing (..)

import Array
import Evergreen.V360.Go
import Evergreen.V360.Id
import Evergreen.V360.Message
import Evergreen.V360.SecretId
import Evergreen.V360.SheepGame
import Evergreen.V360.UserSession
import Evergreen.V360.WordSpellingGame
import SeqDict


type Msg
    = GoGameMsg Evergreen.V360.Go.GameMsg
    | GoSetupMsg Evergreen.V360.Go.SetupMsg
    | WordSpellingGameMsg Evergreen.V360.WordSpellingGame.GameMsg
    | WordSpellingSetupMsg Evergreen.V360.WordSpellingGame.SetupMsg
    | SheepGameMsg Evergreen.V360.SheepGame.GameMsg
    | SheepSetupMsg Evergreen.V360.SheepGame.SetupMsg
    | PressedShareMatch (Evergreen.V360.Id.Id Evergreen.V360.Id.ChannelMessageId)
    | PressedCopyLink String
    | SelectedMatch (Evergreen.V360.Id.Id Evergreen.V360.Id.ChannelMessageId)
    | PressedReset
    | PressedSelectGame Evergreen.V360.Message.GameType
    | CheckedSheepGameQuestionsDebounce Int
    | CheckedSheepGameSaveDebounce (Evergreen.V360.Id.Id Evergreen.V360.Id.ChannelMessageId) Evergreen.V360.SheepGame.Input Int
    | NoOpMsg


type FrontendGameData
    = FrontendGameData_Go Evergreen.V360.Go.ValidatedSetup (Array.Array Evergreen.V360.Go.ActionWithTime) Evergreen.V360.Go.Shared
    | FrontendGameData_WordSpellingGame Evergreen.V360.WordSpellingGame.ValidatedSetup (Array.Array Evergreen.V360.WordSpellingGame.ActionWithTime) Evergreen.V360.WordSpellingGame.Shared
    | FrontendGameData_SheepGame Evergreen.V360.SheepGame.ValidatedSetup (Array.Array Evergreen.V360.SheepGame.ActionWithTime) Evergreen.V360.SheepGame.Shared


type MatchData
    = MatchData
        { data : FrontendGameData
        , publicLink : Maybe (Evergreen.V360.SecretId.SecretId Evergreen.V360.Id.GamePublicId)
        }
    | MatchNotLoaded Evergreen.V360.Message.GameType


type BackendGameData
    = GameData_Go Evergreen.V360.Go.ValidatedSetup (Array.Array Evergreen.V360.Go.ActionWithTime)
    | GameData_WordSpellingGame Evergreen.V360.WordSpellingGame.ValidatedSetup (Array.Array Evergreen.V360.WordSpellingGame.ActionWithTime) Evergreen.V360.WordSpellingGame.Shared
    | GameData_SheepGame Evergreen.V360.SheepGame.ValidatedSetup (Array.Array Evergreen.V360.SheepGame.ActionWithTime) Evergreen.V360.SheepGame.Shared


type alias LoadedMatch =
    { gameData : BackendGameData
    , publicLink : Maybe (Evergreen.V360.SecretId.SecretId Evergreen.V360.Id.GamePublicId)
    }


type LocalChange
    = CreatePublicLink (Evergreen.V360.Id.Id Evergreen.V360.Id.ChannelMessageId) (Evergreen.V360.UserSession.ToBeFilledInByBackend (Evergreen.V360.SecretId.SecretId Evergreen.V360.Id.GamePublicId))
    | LoadMatch (Evergreen.V360.Id.Id Evergreen.V360.Id.ChannelMessageId) (Evergreen.V360.UserSession.ToBeFilledInByBackend LoadedMatch)
    | LocalChange_Go (Evergreen.V360.Id.Id Evergreen.V360.Id.ChannelMessageId) Evergreen.V360.Go.LocalChange
    | LocalChange_WordSpellingGame (Evergreen.V360.Id.Id Evergreen.V360.Id.ChannelMessageId) Evergreen.V360.WordSpellingGame.LocalChange
    | LocalChange_SheepGame (Evergreen.V360.Id.Id Evergreen.V360.Id.ChannelMessageId) Evergreen.V360.SheepGame.LocalChange


type Game
    = GoModel_Game Evergreen.V360.Go.GameModel
    | WordSpellingGame_Game Evergreen.V360.WordSpellingGame.GameData
    | SheepGame_Game Evergreen.V360.SheepGame.GameData


type Setup
    = GameSelect
    | GoModel_Setup Evergreen.V360.Go.SetupModel
    | WordSpellingGame_Setup Evergreen.V360.WordSpellingGame.SetupModel
    | SheepGame_Setup Evergreen.V360.SheepGame.SetupModel


type alias Model =
    { startedGames : SeqDict.SeqDict (Evergreen.V360.Id.Id Evergreen.V360.Id.ChannelMessageId) Game
    , setup : Setup
    , sheepGameQuestionsCounter : Int
    , sheepGameSaveCounters : SeqDict.SeqDict ( Evergreen.V360.Id.Id Evergreen.V360.Id.ChannelMessageId, Evergreen.V360.SheepGame.Input ) Int
    }
