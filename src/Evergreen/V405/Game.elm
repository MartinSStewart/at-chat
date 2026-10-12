module Evergreen.V405.Game exposing (..)

import Array
import Evergreen.V405.Go
import Evergreen.V405.Id
import Evergreen.V405.Message
import Evergreen.V405.SecretId
import Evergreen.V405.SheepGame
import Evergreen.V405.UserSession
import Evergreen.V405.WordSpellingGame
import SeqDict


type Msg
    = GoGameMsg Evergreen.V405.Go.GameMsg
    | GoSetupMsg Evergreen.V405.Go.SetupMsg
    | WordSpellingGameMsg Evergreen.V405.WordSpellingGame.GameMsg
    | WordSpellingSetupMsg Evergreen.V405.WordSpellingGame.SetupMsg
    | SheepGameMsg Evergreen.V405.SheepGame.GameMsg
    | SheepSetupMsg Evergreen.V405.SheepGame.SetupMsg
    | PressedShareMatch (Evergreen.V405.Id.Id Evergreen.V405.Id.ChannelMessageId)
    | PressedCopyLink String
    | SelectedMatch (Evergreen.V405.Id.Id Evergreen.V405.Id.ChannelMessageId)
    | PressedReset
    | PressedSelectGame Evergreen.V405.Message.GameType
    | NoOpMsg


type FrontendGameData
    = FrontendGameData_Go Evergreen.V405.Go.ValidatedSetup (Array.Array Evergreen.V405.Go.ActionWithTime) Evergreen.V405.Go.Shared
    | FrontendGameData_WordSpellingGame Evergreen.V405.WordSpellingGame.ValidatedSetup (Array.Array Evergreen.V405.WordSpellingGame.ActionWithTime) Evergreen.V405.WordSpellingGame.Shared
    | FrontendGameData_SheepGame Evergreen.V405.SheepGame.ValidatedSetup (Array.Array Evergreen.V405.SheepGame.ActionWithTime) Evergreen.V405.SheepGame.Shared


type MatchData
    = MatchData
        { data : FrontendGameData
        , publicLink : Maybe (Evergreen.V405.SecretId.SecretId Evergreen.V405.Id.GamePublicId)
        }
    | MatchNotLoaded Evergreen.V405.Message.GameType


type BackendGameData
    = GameData_Go Evergreen.V405.Go.ValidatedSetup (Array.Array Evergreen.V405.Go.ActionWithTime)
    | GameData_WordSpellingGame Evergreen.V405.WordSpellingGame.ValidatedSetup (Array.Array Evergreen.V405.WordSpellingGame.ActionWithTime) Evergreen.V405.WordSpellingGame.Shared
    | GameData_SheepGame Evergreen.V405.SheepGame.ValidatedSetup (Array.Array Evergreen.V405.SheepGame.ActionWithTime) Evergreen.V405.SheepGame.Shared


type alias LoadedMatch =
    { gameData : BackendGameData
    , publicLink : Maybe (Evergreen.V405.SecretId.SecretId Evergreen.V405.Id.GamePublicId)
    }


type LocalChange
    = CreatePublicLink (Evergreen.V405.Id.Id Evergreen.V405.Id.ChannelMessageId) (Evergreen.V405.UserSession.ToBeFilledInByBackend (Evergreen.V405.SecretId.SecretId Evergreen.V405.Id.GamePublicId))
    | LoadMatch (Evergreen.V405.Id.Id Evergreen.V405.Id.ChannelMessageId) (Evergreen.V405.UserSession.ToBeFilledInByBackend LoadedMatch)
    | LocalChange_Go (Evergreen.V405.Id.Id Evergreen.V405.Id.ChannelMessageId) Evergreen.V405.Go.LocalChange
    | LocalChange_WordSpellingGame (Evergreen.V405.Id.Id Evergreen.V405.Id.ChannelMessageId) Evergreen.V405.WordSpellingGame.LocalChange
    | LocalChange_SheepGame (Evergreen.V405.Id.Id Evergreen.V405.Id.ChannelMessageId) Evergreen.V405.SheepGame.LocalChange


type Game
    = GoModel_Game Evergreen.V405.Go.GameModel
    | WordSpellingGame_Game Evergreen.V405.WordSpellingGame.GameData
    | SheepGame_Game Evergreen.V405.SheepGame.GameData


type Setup
    = GameSelect
    | GoModel_Setup Evergreen.V405.Go.SetupModel
    | WordSpellingGame_Setup Evergreen.V405.WordSpellingGame.SetupModel
    | SheepGame_Setup Evergreen.V405.SheepGame.SetupModel


type alias Model =
    { startedGames : SeqDict.SeqDict (Evergreen.V405.Id.Id Evergreen.V405.Id.ChannelMessageId) Game
    , setup : Setup
    , sheepGameQuestionsCounter : Int
    , sheepGameSaveCounters : SeqDict.SeqDict ( Evergreen.V405.Id.Id Evergreen.V405.Id.ChannelMessageId, Evergreen.V405.SheepGame.Input ) Int
    }
