module Evergreen.V411.Game exposing (..)

import Array
import Evergreen.V411.Go
import Evergreen.V411.Id
import Evergreen.V411.Message
import Evergreen.V411.SecretId
import Evergreen.V411.SheepGame
import Evergreen.V411.UserSession
import Evergreen.V411.WordSpellingGame
import SeqDict


type Msg
    = GoGameMsg Evergreen.V411.Go.GameMsg
    | GoSetupMsg Evergreen.V411.Go.SetupMsg
    | WordSpellingGameMsg Evergreen.V411.WordSpellingGame.GameMsg
    | WordSpellingSetupMsg Evergreen.V411.WordSpellingGame.SetupMsg
    | SheepGameMsg Evergreen.V411.SheepGame.GameMsg
    | SheepSetupMsg Evergreen.V411.SheepGame.SetupMsg
    | PressedShareMatch (Evergreen.V411.Id.Id Evergreen.V411.Id.ChannelMessageId)
    | PressedCopyLink String
    | SelectedMatch (Evergreen.V411.Id.Id Evergreen.V411.Id.ChannelMessageId)
    | PressedReset
    | PressedSelectGame Evergreen.V411.Message.GameType
    | NoOpMsg


type FrontendGameData
    = FrontendGameData_Go Evergreen.V411.Go.ValidatedSetup (Array.Array Evergreen.V411.Go.ActionWithTime) Evergreen.V411.Go.Shared
    | FrontendGameData_WordSpellingGame Evergreen.V411.WordSpellingGame.ValidatedSetup (Array.Array Evergreen.V411.WordSpellingGame.ActionWithTime) Evergreen.V411.WordSpellingGame.Shared
    | FrontendGameData_SheepGame Evergreen.V411.SheepGame.ValidatedSetup (Array.Array Evergreen.V411.SheepGame.ActionWithTime) Evergreen.V411.SheepGame.Shared


type MatchData
    = MatchData
        { data : FrontendGameData
        , publicLink : Maybe (Evergreen.V411.SecretId.SecretId Evergreen.V411.Id.GamePublicId)
        }
    | MatchNotLoaded Evergreen.V411.Message.GameType


type BackendGameData
    = GameData_Go Evergreen.V411.Go.ValidatedSetup (Array.Array Evergreen.V411.Go.ActionWithTime)
    | GameData_WordSpellingGame Evergreen.V411.WordSpellingGame.ValidatedSetup (Array.Array Evergreen.V411.WordSpellingGame.ActionWithTime) Evergreen.V411.WordSpellingGame.Shared
    | GameData_SheepGame Evergreen.V411.SheepGame.ValidatedSetup (Array.Array Evergreen.V411.SheepGame.ActionWithTime) Evergreen.V411.SheepGame.Shared


type alias LoadedMatch =
    { gameData : BackendGameData
    , publicLink : Maybe (Evergreen.V411.SecretId.SecretId Evergreen.V411.Id.GamePublicId)
    }


type LocalChange
    = CreatePublicLink (Evergreen.V411.Id.Id Evergreen.V411.Id.ChannelMessageId) (Evergreen.V411.UserSession.ToBeFilledInByBackend (Evergreen.V411.SecretId.SecretId Evergreen.V411.Id.GamePublicId))
    | LoadMatch (Evergreen.V411.Id.Id Evergreen.V411.Id.ChannelMessageId) (Evergreen.V411.UserSession.ToBeFilledInByBackend LoadedMatch)
    | LocalChange_Go (Evergreen.V411.Id.Id Evergreen.V411.Id.ChannelMessageId) Evergreen.V411.Go.LocalChange
    | LocalChange_WordSpellingGame (Evergreen.V411.Id.Id Evergreen.V411.Id.ChannelMessageId) Evergreen.V411.WordSpellingGame.LocalChange
    | LocalChange_SheepGame (Evergreen.V411.Id.Id Evergreen.V411.Id.ChannelMessageId) Evergreen.V411.SheepGame.LocalChange


type Game
    = GoModel_Game Evergreen.V411.Go.GameModel
    | WordSpellingGame_Game Evergreen.V411.WordSpellingGame.GameData
    | SheepGame_Game Evergreen.V411.SheepGame.GameData


type Setup
    = GameSelect
    | GoModel_Setup Evergreen.V411.Go.SetupModel
    | WordSpellingGame_Setup Evergreen.V411.WordSpellingGame.SetupModel
    | SheepGame_Setup Evergreen.V411.SheepGame.SetupModel


type alias Model =
    { startedGames : SeqDict.SeqDict (Evergreen.V411.Id.Id Evergreen.V411.Id.ChannelMessageId) Game
    , setup : Setup
    , sheepGameQuestionsCounter : Int
    , sheepGameSaveCounters : SeqDict.SeqDict ( Evergreen.V411.Id.Id Evergreen.V411.Id.ChannelMessageId, Evergreen.V411.SheepGame.Input ) Int
    }
