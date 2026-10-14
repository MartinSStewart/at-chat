module Evergreen.V407.Game exposing (..)

import Array
import Evergreen.V407.Go
import Evergreen.V407.Id
import Evergreen.V407.Message
import Evergreen.V407.SecretId
import Evergreen.V407.SheepGame
import Evergreen.V407.UserSession
import Evergreen.V407.WordSpellingGame
import SeqDict


type Msg
    = GoGameMsg Evergreen.V407.Go.GameMsg
    | GoSetupMsg Evergreen.V407.Go.SetupMsg
    | WordSpellingGameMsg Evergreen.V407.WordSpellingGame.GameMsg
    | WordSpellingSetupMsg Evergreen.V407.WordSpellingGame.SetupMsg
    | SheepGameMsg Evergreen.V407.SheepGame.GameMsg
    | SheepSetupMsg Evergreen.V407.SheepGame.SetupMsg
    | PressedShareMatch (Evergreen.V407.Id.Id Evergreen.V407.Id.ChannelMessageId)
    | PressedCopyLink String
    | SelectedMatch (Evergreen.V407.Id.Id Evergreen.V407.Id.ChannelMessageId)
    | PressedReset
    | PressedSelectGame Evergreen.V407.Message.GameType
    | NoOpMsg


type FrontendGameData
    = FrontendGameData_Go Evergreen.V407.Go.ValidatedSetup (Array.Array Evergreen.V407.Go.ActionWithTime) Evergreen.V407.Go.Shared
    | FrontendGameData_WordSpellingGame Evergreen.V407.WordSpellingGame.ValidatedSetup (Array.Array Evergreen.V407.WordSpellingGame.ActionWithTime) Evergreen.V407.WordSpellingGame.Shared
    | FrontendGameData_SheepGame Evergreen.V407.SheepGame.ValidatedSetup (Array.Array Evergreen.V407.SheepGame.ActionWithTime) Evergreen.V407.SheepGame.Shared


type MatchData
    = MatchData
        { data : FrontendGameData
        , publicLink : Maybe (Evergreen.V407.SecretId.SecretId Evergreen.V407.Id.GamePublicId)
        }
    | MatchNotLoaded Evergreen.V407.Message.GameType


type BackendGameData
    = GameData_Go Evergreen.V407.Go.ValidatedSetup (Array.Array Evergreen.V407.Go.ActionWithTime)
    | GameData_WordSpellingGame Evergreen.V407.WordSpellingGame.ValidatedSetup (Array.Array Evergreen.V407.WordSpellingGame.ActionWithTime) Evergreen.V407.WordSpellingGame.Shared
    | GameData_SheepGame Evergreen.V407.SheepGame.ValidatedSetup (Array.Array Evergreen.V407.SheepGame.ActionWithTime) Evergreen.V407.SheepGame.Shared


type alias LoadedMatch =
    { gameData : BackendGameData
    , publicLink : Maybe (Evergreen.V407.SecretId.SecretId Evergreen.V407.Id.GamePublicId)
    }


type LocalChange
    = CreatePublicLink (Evergreen.V407.Id.Id Evergreen.V407.Id.ChannelMessageId) (Evergreen.V407.UserSession.ToBeFilledInByBackend (Evergreen.V407.SecretId.SecretId Evergreen.V407.Id.GamePublicId))
    | LoadMatch (Evergreen.V407.Id.Id Evergreen.V407.Id.ChannelMessageId) (Evergreen.V407.UserSession.ToBeFilledInByBackend LoadedMatch)
    | LocalChange_Go (Evergreen.V407.Id.Id Evergreen.V407.Id.ChannelMessageId) Evergreen.V407.Go.LocalChange
    | LocalChange_WordSpellingGame (Evergreen.V407.Id.Id Evergreen.V407.Id.ChannelMessageId) Evergreen.V407.WordSpellingGame.LocalChange
    | LocalChange_SheepGame (Evergreen.V407.Id.Id Evergreen.V407.Id.ChannelMessageId) Evergreen.V407.SheepGame.LocalChange


type Game
    = GoModel_Game Evergreen.V407.Go.GameModel
    | WordSpellingGame_Game Evergreen.V407.WordSpellingGame.GameData
    | SheepGame_Game Evergreen.V407.SheepGame.GameData


type Setup
    = GameSelect
    | GoModel_Setup Evergreen.V407.Go.SetupModel
    | WordSpellingGame_Setup Evergreen.V407.WordSpellingGame.SetupModel
    | SheepGame_Setup Evergreen.V407.SheepGame.SetupModel


type alias Model =
    { startedGames : SeqDict.SeqDict (Evergreen.V407.Id.Id Evergreen.V407.Id.ChannelMessageId) Game
    , setup : Setup
    , sheepGameQuestionsCounter : Int
    , sheepGameSaveCounters : SeqDict.SeqDict ( Evergreen.V407.Id.Id Evergreen.V407.Id.ChannelMessageId, Evergreen.V407.SheepGame.Input ) Int
    }
