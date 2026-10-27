module Evergreen.V417.Game exposing (..)

import Array
import Evergreen.V417.Go
import Evergreen.V417.Id
import Evergreen.V417.Message
import Evergreen.V417.SecretId
import Evergreen.V417.SheepGame
import Evergreen.V417.UserSession
import Evergreen.V417.WordSpellingGame
import SeqDict


type Msg
    = GoGameMsg Evergreen.V417.Go.GameMsg
    | GoSetupMsg Evergreen.V417.Go.SetupMsg
    | WordSpellingGameMsg Evergreen.V417.WordSpellingGame.GameMsg
    | WordSpellingSetupMsg Evergreen.V417.WordSpellingGame.SetupMsg
    | SheepGameMsg Evergreen.V417.SheepGame.GameMsg
    | SheepSetupMsg Evergreen.V417.SheepGame.SetupMsg
    | PressedShareMatch (Evergreen.V417.Id.Id Evergreen.V417.Id.ChannelMessageId)
    | PressedCopyLink String
    | SelectedMatch (Evergreen.V417.Id.Id Evergreen.V417.Id.ChannelMessageId)
    | PressedReset
    | PressedSelectGame Evergreen.V417.Message.GameType
    | NoOpMsg


type FrontendGameData
    = FrontendGameData_Go Evergreen.V417.Go.ValidatedSetup (Array.Array Evergreen.V417.Go.ActionWithTime) Evergreen.V417.Go.Shared
    | FrontendGameData_WordSpellingGame Evergreen.V417.WordSpellingGame.ValidatedSetup (Array.Array Evergreen.V417.WordSpellingGame.ActionWithTime) Evergreen.V417.WordSpellingGame.Shared
    | FrontendGameData_SheepGame Evergreen.V417.SheepGame.ValidatedSetup (Array.Array Evergreen.V417.SheepGame.ActionWithTime) Evergreen.V417.SheepGame.Shared


type MatchData
    = MatchData
        { data : FrontendGameData
        , publicLink : Maybe (Evergreen.V417.SecretId.SecretId Evergreen.V417.Id.GamePublicId)
        }
    | MatchNotLoaded Evergreen.V417.Message.GameType


type BackendGameData
    = GameData_Go Evergreen.V417.Go.ValidatedSetup (Array.Array Evergreen.V417.Go.ActionWithTime)
    | GameData_WordSpellingGame Evergreen.V417.WordSpellingGame.ValidatedSetup (Array.Array Evergreen.V417.WordSpellingGame.ActionWithTime) Evergreen.V417.WordSpellingGame.Shared
    | GameData_SheepGame Evergreen.V417.SheepGame.ValidatedSetup (Array.Array Evergreen.V417.SheepGame.ActionWithTime) Evergreen.V417.SheepGame.Shared


type alias LoadedMatch =
    { gameData : BackendGameData
    , publicLink : Maybe (Evergreen.V417.SecretId.SecretId Evergreen.V417.Id.GamePublicId)
    }


type LocalChange
    = CreatePublicLink (Evergreen.V417.Id.Id Evergreen.V417.Id.ChannelMessageId) (Evergreen.V417.UserSession.ToBeFilledInByBackend (Evergreen.V417.SecretId.SecretId Evergreen.V417.Id.GamePublicId))
    | LoadMatch (Evergreen.V417.Id.Id Evergreen.V417.Id.ChannelMessageId) (Evergreen.V417.UserSession.ToBeFilledInByBackend LoadedMatch)
    | LocalChange_Go (Evergreen.V417.Id.Id Evergreen.V417.Id.ChannelMessageId) Evergreen.V417.Go.LocalChange
    | LocalChange_WordSpellingGame (Evergreen.V417.Id.Id Evergreen.V417.Id.ChannelMessageId) Evergreen.V417.WordSpellingGame.LocalChange
    | LocalChange_SheepGame (Evergreen.V417.Id.Id Evergreen.V417.Id.ChannelMessageId) Evergreen.V417.SheepGame.LocalChange


type Game
    = GoModel_Game Evergreen.V417.Go.GameModel
    | WordSpellingGame_Game Evergreen.V417.WordSpellingGame.GameData
    | SheepGame_Game Evergreen.V417.SheepGame.GameData


type Setup
    = GameSelect
    | GoModel_Setup Evergreen.V417.Go.SetupModel
    | WordSpellingGame_Setup Evergreen.V417.WordSpellingGame.SetupModel
    | SheepGame_Setup Evergreen.V417.SheepGame.SetupModel


type alias Model =
    { startedGames : SeqDict.SeqDict (Evergreen.V417.Id.Id Evergreen.V417.Id.ChannelMessageId) Game
    , setup : Setup
    , sheepGameQuestionsCounter : Int
    , sheepGameSaveCounters : SeqDict.SeqDict ( Evergreen.V417.Id.Id Evergreen.V417.Id.ChannelMessageId, Evergreen.V417.SheepGame.Input ) Int
    }
