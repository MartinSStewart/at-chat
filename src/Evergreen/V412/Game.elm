module Evergreen.V412.Game exposing (..)

import Array
import Evergreen.V412.Go
import Evergreen.V412.Id
import Evergreen.V412.Message
import Evergreen.V412.SecretId
import Evergreen.V412.SheepGame
import Evergreen.V412.UserSession
import Evergreen.V412.WordSpellingGame
import SeqDict


type Msg
    = GoGameMsg Evergreen.V412.Go.GameMsg
    | GoSetupMsg Evergreen.V412.Go.SetupMsg
    | WordSpellingGameMsg Evergreen.V412.WordSpellingGame.GameMsg
    | WordSpellingSetupMsg Evergreen.V412.WordSpellingGame.SetupMsg
    | SheepGameMsg Evergreen.V412.SheepGame.GameMsg
    | SheepSetupMsg Evergreen.V412.SheepGame.SetupMsg
    | PressedShareMatch (Evergreen.V412.Id.Id Evergreen.V412.Id.ChannelMessageId)
    | PressedCopyLink String
    | SelectedMatch (Evergreen.V412.Id.Id Evergreen.V412.Id.ChannelMessageId)
    | PressedReset
    | PressedSelectGame Evergreen.V412.Message.GameType
    | NoOpMsg


type FrontendGameData
    = FrontendGameData_Go Evergreen.V412.Go.ValidatedSetup (Array.Array Evergreen.V412.Go.ActionWithTime) Evergreen.V412.Go.Shared
    | FrontendGameData_WordSpellingGame Evergreen.V412.WordSpellingGame.ValidatedSetup (Array.Array Evergreen.V412.WordSpellingGame.ActionWithTime) Evergreen.V412.WordSpellingGame.Shared
    | FrontendGameData_SheepGame Evergreen.V412.SheepGame.ValidatedSetup (Array.Array Evergreen.V412.SheepGame.ActionWithTime) Evergreen.V412.SheepGame.Shared


type MatchData
    = MatchData
        { data : FrontendGameData
        , publicLink : Maybe (Evergreen.V412.SecretId.SecretId Evergreen.V412.Id.GamePublicId)
        }
    | MatchNotLoaded Evergreen.V412.Message.GameType


type BackendGameData
    = GameData_Go Evergreen.V412.Go.ValidatedSetup (Array.Array Evergreen.V412.Go.ActionWithTime)
    | GameData_WordSpellingGame Evergreen.V412.WordSpellingGame.ValidatedSetup (Array.Array Evergreen.V412.WordSpellingGame.ActionWithTime) Evergreen.V412.WordSpellingGame.Shared
    | GameData_SheepGame Evergreen.V412.SheepGame.ValidatedSetup (Array.Array Evergreen.V412.SheepGame.ActionWithTime) Evergreen.V412.SheepGame.Shared


type alias LoadedMatch =
    { gameData : BackendGameData
    , publicLink : Maybe (Evergreen.V412.SecretId.SecretId Evergreen.V412.Id.GamePublicId)
    }


type LocalChange
    = CreatePublicLink (Evergreen.V412.Id.Id Evergreen.V412.Id.ChannelMessageId) (Evergreen.V412.UserSession.ToBeFilledInByBackend (Evergreen.V412.SecretId.SecretId Evergreen.V412.Id.GamePublicId))
    | LoadMatch (Evergreen.V412.Id.Id Evergreen.V412.Id.ChannelMessageId) (Evergreen.V412.UserSession.ToBeFilledInByBackend LoadedMatch)
    | LocalChange_Go (Evergreen.V412.Id.Id Evergreen.V412.Id.ChannelMessageId) Evergreen.V412.Go.LocalChange
    | LocalChange_WordSpellingGame (Evergreen.V412.Id.Id Evergreen.V412.Id.ChannelMessageId) Evergreen.V412.WordSpellingGame.LocalChange
    | LocalChange_SheepGame (Evergreen.V412.Id.Id Evergreen.V412.Id.ChannelMessageId) Evergreen.V412.SheepGame.LocalChange


type Game
    = GoModel_Game Evergreen.V412.Go.GameModel
    | WordSpellingGame_Game Evergreen.V412.WordSpellingGame.GameData
    | SheepGame_Game Evergreen.V412.SheepGame.GameData


type Setup
    = GameSelect
    | GoModel_Setup Evergreen.V412.Go.SetupModel
    | WordSpellingGame_Setup Evergreen.V412.WordSpellingGame.SetupModel
    | SheepGame_Setup Evergreen.V412.SheepGame.SetupModel


type alias Model =
    { startedGames : SeqDict.SeqDict (Evergreen.V412.Id.Id Evergreen.V412.Id.ChannelMessageId) Game
    , setup : Setup
    , sheepGameQuestionsCounter : Int
    , sheepGameSaveCounters : SeqDict.SeqDict ( Evergreen.V412.Id.Id Evergreen.V412.Id.ChannelMessageId, Evergreen.V412.SheepGame.Input ) Int
    }
