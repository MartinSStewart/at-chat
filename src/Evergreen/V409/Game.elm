module Evergreen.V409.Game exposing (..)

import Array
import Evergreen.V409.Go
import Evergreen.V409.Id
import Evergreen.V409.Message
import Evergreen.V409.SecretId
import Evergreen.V409.SheepGame
import Evergreen.V409.UserSession
import Evergreen.V409.WordSpellingGame
import SeqDict


type Msg
    = GoGameMsg Evergreen.V409.Go.GameMsg
    | GoSetupMsg Evergreen.V409.Go.SetupMsg
    | WordSpellingGameMsg Evergreen.V409.WordSpellingGame.GameMsg
    | WordSpellingSetupMsg Evergreen.V409.WordSpellingGame.SetupMsg
    | SheepGameMsg Evergreen.V409.SheepGame.GameMsg
    | SheepSetupMsg Evergreen.V409.SheepGame.SetupMsg
    | PressedShareMatch (Evergreen.V409.Id.Id Evergreen.V409.Id.ChannelMessageId)
    | PressedCopyLink String
    | SelectedMatch (Evergreen.V409.Id.Id Evergreen.V409.Id.ChannelMessageId)
    | PressedReset
    | PressedSelectGame Evergreen.V409.Message.GameType
    | NoOpMsg


type FrontendGameData
    = FrontendGameData_Go Evergreen.V409.Go.ValidatedSetup (Array.Array Evergreen.V409.Go.ActionWithTime) Evergreen.V409.Go.Shared
    | FrontendGameData_WordSpellingGame Evergreen.V409.WordSpellingGame.ValidatedSetup (Array.Array Evergreen.V409.WordSpellingGame.ActionWithTime) Evergreen.V409.WordSpellingGame.Shared
    | FrontendGameData_SheepGame Evergreen.V409.SheepGame.ValidatedSetup (Array.Array Evergreen.V409.SheepGame.ActionWithTime) Evergreen.V409.SheepGame.Shared


type MatchData
    = MatchData
        { data : FrontendGameData
        , publicLink : Maybe (Evergreen.V409.SecretId.SecretId Evergreen.V409.Id.GamePublicId)
        }
    | MatchNotLoaded Evergreen.V409.Message.GameType


type BackendGameData
    = GameData_Go Evergreen.V409.Go.ValidatedSetup (Array.Array Evergreen.V409.Go.ActionWithTime)
    | GameData_WordSpellingGame Evergreen.V409.WordSpellingGame.ValidatedSetup (Array.Array Evergreen.V409.WordSpellingGame.ActionWithTime) Evergreen.V409.WordSpellingGame.Shared
    | GameData_SheepGame Evergreen.V409.SheepGame.ValidatedSetup (Array.Array Evergreen.V409.SheepGame.ActionWithTime) Evergreen.V409.SheepGame.Shared


type alias LoadedMatch =
    { gameData : BackendGameData
    , publicLink : Maybe (Evergreen.V409.SecretId.SecretId Evergreen.V409.Id.GamePublicId)
    }


type LocalChange
    = CreatePublicLink (Evergreen.V409.Id.Id Evergreen.V409.Id.ChannelMessageId) (Evergreen.V409.UserSession.ToBeFilledInByBackend (Evergreen.V409.SecretId.SecretId Evergreen.V409.Id.GamePublicId))
    | LoadMatch (Evergreen.V409.Id.Id Evergreen.V409.Id.ChannelMessageId) (Evergreen.V409.UserSession.ToBeFilledInByBackend LoadedMatch)
    | LocalChange_Go (Evergreen.V409.Id.Id Evergreen.V409.Id.ChannelMessageId) Evergreen.V409.Go.LocalChange
    | LocalChange_WordSpellingGame (Evergreen.V409.Id.Id Evergreen.V409.Id.ChannelMessageId) Evergreen.V409.WordSpellingGame.LocalChange
    | LocalChange_SheepGame (Evergreen.V409.Id.Id Evergreen.V409.Id.ChannelMessageId) Evergreen.V409.SheepGame.LocalChange


type Game
    = GoModel_Game Evergreen.V409.Go.GameModel
    | WordSpellingGame_Game Evergreen.V409.WordSpellingGame.GameData
    | SheepGame_Game Evergreen.V409.SheepGame.GameData


type Setup
    = GameSelect
    | GoModel_Setup Evergreen.V409.Go.SetupModel
    | WordSpellingGame_Setup Evergreen.V409.WordSpellingGame.SetupModel
    | SheepGame_Setup Evergreen.V409.SheepGame.SetupModel


type alias Model =
    { startedGames : SeqDict.SeqDict (Evergreen.V409.Id.Id Evergreen.V409.Id.ChannelMessageId) Game
    , setup : Setup
    , sheepGameQuestionsCounter : Int
    , sheepGameSaveCounters : SeqDict.SeqDict ( Evergreen.V409.Id.Id Evergreen.V409.Id.ChannelMessageId, Evergreen.V409.SheepGame.Input ) Int
    }
