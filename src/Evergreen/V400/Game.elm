module Evergreen.V400.Game exposing (..)

import Array
import Evergreen.V400.Go
import Evergreen.V400.Id
import Evergreen.V400.Message
import Evergreen.V400.SecretId
import Evergreen.V400.SheepGame
import Evergreen.V400.UserSession
import Evergreen.V400.WordSpellingGame
import SeqDict


type Msg
    = GoGameMsg Evergreen.V400.Go.GameMsg
    | GoSetupMsg Evergreen.V400.Go.SetupMsg
    | WordSpellingGameMsg Evergreen.V400.WordSpellingGame.GameMsg
    | WordSpellingSetupMsg Evergreen.V400.WordSpellingGame.SetupMsg
    | SheepGameMsg Evergreen.V400.SheepGame.GameMsg
    | SheepSetupMsg Evergreen.V400.SheepGame.SetupMsg
    | PressedShareMatch (Evergreen.V400.Id.Id Evergreen.V400.Id.ChannelMessageId)
    | PressedCopyLink String
    | SelectedMatch (Evergreen.V400.Id.Id Evergreen.V400.Id.ChannelMessageId)
    | PressedReset
    | PressedSelectGame Evergreen.V400.Message.GameType
    | NoOpMsg


type FrontendGameData
    = FrontendGameData_Go Evergreen.V400.Go.ValidatedSetup (Array.Array Evergreen.V400.Go.ActionWithTime) Evergreen.V400.Go.Shared
    | FrontendGameData_WordSpellingGame Evergreen.V400.WordSpellingGame.ValidatedSetup (Array.Array Evergreen.V400.WordSpellingGame.ActionWithTime) Evergreen.V400.WordSpellingGame.Shared
    | FrontendGameData_SheepGame Evergreen.V400.SheepGame.ValidatedSetup (Array.Array Evergreen.V400.SheepGame.ActionWithTime) Evergreen.V400.SheepGame.Shared


type MatchData
    = MatchData
        { data : FrontendGameData
        , publicLink : Maybe (Evergreen.V400.SecretId.SecretId Evergreen.V400.Id.GamePublicId)
        }
    | MatchNotLoaded Evergreen.V400.Message.GameType


type BackendGameData
    = GameData_Go Evergreen.V400.Go.ValidatedSetup (Array.Array Evergreen.V400.Go.ActionWithTime)
    | GameData_WordSpellingGame Evergreen.V400.WordSpellingGame.ValidatedSetup (Array.Array Evergreen.V400.WordSpellingGame.ActionWithTime) Evergreen.V400.WordSpellingGame.Shared
    | GameData_SheepGame Evergreen.V400.SheepGame.ValidatedSetup (Array.Array Evergreen.V400.SheepGame.ActionWithTime) Evergreen.V400.SheepGame.Shared


type alias LoadedMatch =
    { gameData : BackendGameData
    , publicLink : Maybe (Evergreen.V400.SecretId.SecretId Evergreen.V400.Id.GamePublicId)
    }


type LocalChange
    = CreatePublicLink (Evergreen.V400.Id.Id Evergreen.V400.Id.ChannelMessageId) (Evergreen.V400.UserSession.ToBeFilledInByBackend (Evergreen.V400.SecretId.SecretId Evergreen.V400.Id.GamePublicId))
    | LoadMatch (Evergreen.V400.Id.Id Evergreen.V400.Id.ChannelMessageId) (Evergreen.V400.UserSession.ToBeFilledInByBackend LoadedMatch)
    | LocalChange_Go (Evergreen.V400.Id.Id Evergreen.V400.Id.ChannelMessageId) Evergreen.V400.Go.LocalChange
    | LocalChange_WordSpellingGame (Evergreen.V400.Id.Id Evergreen.V400.Id.ChannelMessageId) Evergreen.V400.WordSpellingGame.LocalChange
    | LocalChange_SheepGame (Evergreen.V400.Id.Id Evergreen.V400.Id.ChannelMessageId) Evergreen.V400.SheepGame.LocalChange


type Game
    = GoModel_Game Evergreen.V400.Go.GameModel
    | WordSpellingGame_Game Evergreen.V400.WordSpellingGame.GameData
    | SheepGame_Game Evergreen.V400.SheepGame.GameData


type Setup
    = GameSelect
    | GoModel_Setup Evergreen.V400.Go.SetupModel
    | WordSpellingGame_Setup Evergreen.V400.WordSpellingGame.SetupModel
    | SheepGame_Setup Evergreen.V400.SheepGame.SetupModel


type alias Model =
    { startedGames : SeqDict.SeqDict (Evergreen.V400.Id.Id Evergreen.V400.Id.ChannelMessageId) Game
    , setup : Setup
    , sheepGameQuestionsCounter : Int
    , sheepGameSaveCounters : SeqDict.SeqDict ( Evergreen.V400.Id.Id Evergreen.V400.Id.ChannelMessageId, Evergreen.V400.SheepGame.Input ) Int
    }
