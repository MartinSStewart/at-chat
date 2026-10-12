module Evergreen.V404.Game exposing (..)

import Array
import Evergreen.V404.Go
import Evergreen.V404.Id
import Evergreen.V404.Message
import Evergreen.V404.SecretId
import Evergreen.V404.SheepGame
import Evergreen.V404.UserSession
import Evergreen.V404.WordSpellingGame
import SeqDict


type Msg
    = GoGameMsg Evergreen.V404.Go.GameMsg
    | GoSetupMsg Evergreen.V404.Go.SetupMsg
    | WordSpellingGameMsg Evergreen.V404.WordSpellingGame.GameMsg
    | WordSpellingSetupMsg Evergreen.V404.WordSpellingGame.SetupMsg
    | SheepGameMsg Evergreen.V404.SheepGame.GameMsg
    | SheepSetupMsg Evergreen.V404.SheepGame.SetupMsg
    | PressedShareMatch (Evergreen.V404.Id.Id Evergreen.V404.Id.ChannelMessageId)
    | PressedCopyLink String
    | SelectedMatch (Evergreen.V404.Id.Id Evergreen.V404.Id.ChannelMessageId)
    | PressedReset
    | PressedSelectGame Evergreen.V404.Message.GameType
    | NoOpMsg


type FrontendGameData
    = FrontendGameData_Go Evergreen.V404.Go.ValidatedSetup (Array.Array Evergreen.V404.Go.ActionWithTime) Evergreen.V404.Go.Shared
    | FrontendGameData_WordSpellingGame Evergreen.V404.WordSpellingGame.ValidatedSetup (Array.Array Evergreen.V404.WordSpellingGame.ActionWithTime) Evergreen.V404.WordSpellingGame.Shared
    | FrontendGameData_SheepGame Evergreen.V404.SheepGame.ValidatedSetup (Array.Array Evergreen.V404.SheepGame.ActionWithTime) Evergreen.V404.SheepGame.Shared


type MatchData
    = MatchData
        { data : FrontendGameData
        , publicLink : Maybe (Evergreen.V404.SecretId.SecretId Evergreen.V404.Id.GamePublicId)
        }
    | MatchNotLoaded Evergreen.V404.Message.GameType


type BackendGameData
    = GameData_Go Evergreen.V404.Go.ValidatedSetup (Array.Array Evergreen.V404.Go.ActionWithTime)
    | GameData_WordSpellingGame Evergreen.V404.WordSpellingGame.ValidatedSetup (Array.Array Evergreen.V404.WordSpellingGame.ActionWithTime) Evergreen.V404.WordSpellingGame.Shared
    | GameData_SheepGame Evergreen.V404.SheepGame.ValidatedSetup (Array.Array Evergreen.V404.SheepGame.ActionWithTime) Evergreen.V404.SheepGame.Shared


type alias LoadedMatch =
    { gameData : BackendGameData
    , publicLink : Maybe (Evergreen.V404.SecretId.SecretId Evergreen.V404.Id.GamePublicId)
    }


type LocalChange
    = CreatePublicLink (Evergreen.V404.Id.Id Evergreen.V404.Id.ChannelMessageId) (Evergreen.V404.UserSession.ToBeFilledInByBackend (Evergreen.V404.SecretId.SecretId Evergreen.V404.Id.GamePublicId))
    | LoadMatch (Evergreen.V404.Id.Id Evergreen.V404.Id.ChannelMessageId) (Evergreen.V404.UserSession.ToBeFilledInByBackend LoadedMatch)
    | LocalChange_Go (Evergreen.V404.Id.Id Evergreen.V404.Id.ChannelMessageId) Evergreen.V404.Go.LocalChange
    | LocalChange_WordSpellingGame (Evergreen.V404.Id.Id Evergreen.V404.Id.ChannelMessageId) Evergreen.V404.WordSpellingGame.LocalChange
    | LocalChange_SheepGame (Evergreen.V404.Id.Id Evergreen.V404.Id.ChannelMessageId) Evergreen.V404.SheepGame.LocalChange


type Game
    = GoModel_Game Evergreen.V404.Go.GameModel
    | WordSpellingGame_Game Evergreen.V404.WordSpellingGame.GameData
    | SheepGame_Game Evergreen.V404.SheepGame.GameData


type Setup
    = GameSelect
    | GoModel_Setup Evergreen.V404.Go.SetupModel
    | WordSpellingGame_Setup Evergreen.V404.WordSpellingGame.SetupModel
    | SheepGame_Setup Evergreen.V404.SheepGame.SetupModel


type alias Model =
    { startedGames : SeqDict.SeqDict (Evergreen.V404.Id.Id Evergreen.V404.Id.ChannelMessageId) Game
    , setup : Setup
    , sheepGameQuestionsCounter : Int
    , sheepGameSaveCounters : SeqDict.SeqDict ( Evergreen.V404.Id.Id Evergreen.V404.Id.ChannelMessageId, Evergreen.V404.SheepGame.Input ) Int
    }
