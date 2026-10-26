module Evergreen.V414.Game exposing (..)

import Array
import Evergreen.V414.Go
import Evergreen.V414.Id
import Evergreen.V414.Message
import Evergreen.V414.SecretId
import Evergreen.V414.SheepGame
import Evergreen.V414.UserSession
import Evergreen.V414.WordSpellingGame
import SeqDict


type Msg
    = GoGameMsg Evergreen.V414.Go.GameMsg
    | GoSetupMsg Evergreen.V414.Go.SetupMsg
    | WordSpellingGameMsg Evergreen.V414.WordSpellingGame.GameMsg
    | WordSpellingSetupMsg Evergreen.V414.WordSpellingGame.SetupMsg
    | SheepGameMsg Evergreen.V414.SheepGame.GameMsg
    | SheepSetupMsg Evergreen.V414.SheepGame.SetupMsg
    | PressedShareMatch (Evergreen.V414.Id.Id Evergreen.V414.Id.ChannelMessageId)
    | PressedCopyLink String
    | SelectedMatch (Evergreen.V414.Id.Id Evergreen.V414.Id.ChannelMessageId)
    | PressedReset
    | PressedSelectGame Evergreen.V414.Message.GameType
    | NoOpMsg


type FrontendGameData
    = FrontendGameData_Go Evergreen.V414.Go.ValidatedSetup (Array.Array Evergreen.V414.Go.ActionWithTime) Evergreen.V414.Go.Shared
    | FrontendGameData_WordSpellingGame Evergreen.V414.WordSpellingGame.ValidatedSetup (Array.Array Evergreen.V414.WordSpellingGame.ActionWithTime) Evergreen.V414.WordSpellingGame.Shared
    | FrontendGameData_SheepGame Evergreen.V414.SheepGame.ValidatedSetup (Array.Array Evergreen.V414.SheepGame.ActionWithTime) Evergreen.V414.SheepGame.Shared


type MatchData
    = MatchData
        { data : FrontendGameData
        , publicLink : Maybe (Evergreen.V414.SecretId.SecretId Evergreen.V414.Id.GamePublicId)
        }
    | MatchNotLoaded Evergreen.V414.Message.GameType


type BackendGameData
    = GameData_Go Evergreen.V414.Go.ValidatedSetup (Array.Array Evergreen.V414.Go.ActionWithTime)
    | GameData_WordSpellingGame Evergreen.V414.WordSpellingGame.ValidatedSetup (Array.Array Evergreen.V414.WordSpellingGame.ActionWithTime) Evergreen.V414.WordSpellingGame.Shared
    | GameData_SheepGame Evergreen.V414.SheepGame.ValidatedSetup (Array.Array Evergreen.V414.SheepGame.ActionWithTime) Evergreen.V414.SheepGame.Shared


type alias LoadedMatch =
    { gameData : BackendGameData
    , publicLink : Maybe (Evergreen.V414.SecretId.SecretId Evergreen.V414.Id.GamePublicId)
    }


type LocalChange
    = CreatePublicLink (Evergreen.V414.Id.Id Evergreen.V414.Id.ChannelMessageId) (Evergreen.V414.UserSession.ToBeFilledInByBackend (Evergreen.V414.SecretId.SecretId Evergreen.V414.Id.GamePublicId))
    | LoadMatch (Evergreen.V414.Id.Id Evergreen.V414.Id.ChannelMessageId) (Evergreen.V414.UserSession.ToBeFilledInByBackend LoadedMatch)
    | LocalChange_Go (Evergreen.V414.Id.Id Evergreen.V414.Id.ChannelMessageId) Evergreen.V414.Go.LocalChange
    | LocalChange_WordSpellingGame (Evergreen.V414.Id.Id Evergreen.V414.Id.ChannelMessageId) Evergreen.V414.WordSpellingGame.LocalChange
    | LocalChange_SheepGame (Evergreen.V414.Id.Id Evergreen.V414.Id.ChannelMessageId) Evergreen.V414.SheepGame.LocalChange


type Game
    = GoModel_Game Evergreen.V414.Go.GameModel
    | WordSpellingGame_Game Evergreen.V414.WordSpellingGame.GameData
    | SheepGame_Game Evergreen.V414.SheepGame.GameData


type Setup
    = GameSelect
    | GoModel_Setup Evergreen.V414.Go.SetupModel
    | WordSpellingGame_Setup Evergreen.V414.WordSpellingGame.SetupModel
    | SheepGame_Setup Evergreen.V414.SheepGame.SetupModel


type alias Model =
    { startedGames : SeqDict.SeqDict (Evergreen.V414.Id.Id Evergreen.V414.Id.ChannelMessageId) Game
    , setup : Setup
    , sheepGameQuestionsCounter : Int
    , sheepGameSaveCounters : SeqDict.SeqDict ( Evergreen.V414.Id.Id Evergreen.V414.Id.ChannelMessageId, Evergreen.V414.SheepGame.Input ) Int
    }
