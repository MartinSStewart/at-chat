module Evergreen.V408.Game exposing (..)

import Array
import Evergreen.V408.Go
import Evergreen.V408.Id
import Evergreen.V408.Message
import Evergreen.V408.SecretId
import Evergreen.V408.SheepGame
import Evergreen.V408.UserSession
import Evergreen.V408.WordSpellingGame
import SeqDict


type Msg
    = GoGameMsg Evergreen.V408.Go.GameMsg
    | GoSetupMsg Evergreen.V408.Go.SetupMsg
    | WordSpellingGameMsg Evergreen.V408.WordSpellingGame.GameMsg
    | WordSpellingSetupMsg Evergreen.V408.WordSpellingGame.SetupMsg
    | SheepGameMsg Evergreen.V408.SheepGame.GameMsg
    | SheepSetupMsg Evergreen.V408.SheepGame.SetupMsg
    | PressedShareMatch (Evergreen.V408.Id.Id Evergreen.V408.Id.ChannelMessageId)
    | PressedCopyLink String
    | SelectedMatch (Evergreen.V408.Id.Id Evergreen.V408.Id.ChannelMessageId)
    | PressedReset
    | PressedSelectGame Evergreen.V408.Message.GameType
    | NoOpMsg


type FrontendGameData
    = FrontendGameData_Go Evergreen.V408.Go.ValidatedSetup (Array.Array Evergreen.V408.Go.ActionWithTime) Evergreen.V408.Go.Shared
    | FrontendGameData_WordSpellingGame Evergreen.V408.WordSpellingGame.ValidatedSetup (Array.Array Evergreen.V408.WordSpellingGame.ActionWithTime) Evergreen.V408.WordSpellingGame.Shared
    | FrontendGameData_SheepGame Evergreen.V408.SheepGame.ValidatedSetup (Array.Array Evergreen.V408.SheepGame.ActionWithTime) Evergreen.V408.SheepGame.Shared


type MatchData
    = MatchData
        { data : FrontendGameData
        , publicLink : Maybe (Evergreen.V408.SecretId.SecretId Evergreen.V408.Id.GamePublicId)
        }
    | MatchNotLoaded Evergreen.V408.Message.GameType


type BackendGameData
    = GameData_Go Evergreen.V408.Go.ValidatedSetup (Array.Array Evergreen.V408.Go.ActionWithTime)
    | GameData_WordSpellingGame Evergreen.V408.WordSpellingGame.ValidatedSetup (Array.Array Evergreen.V408.WordSpellingGame.ActionWithTime) Evergreen.V408.WordSpellingGame.Shared
    | GameData_SheepGame Evergreen.V408.SheepGame.ValidatedSetup (Array.Array Evergreen.V408.SheepGame.ActionWithTime) Evergreen.V408.SheepGame.Shared


type alias LoadedMatch =
    { gameData : BackendGameData
    , publicLink : Maybe (Evergreen.V408.SecretId.SecretId Evergreen.V408.Id.GamePublicId)
    }


type LocalChange
    = CreatePublicLink (Evergreen.V408.Id.Id Evergreen.V408.Id.ChannelMessageId) (Evergreen.V408.UserSession.ToBeFilledInByBackend (Evergreen.V408.SecretId.SecretId Evergreen.V408.Id.GamePublicId))
    | LoadMatch (Evergreen.V408.Id.Id Evergreen.V408.Id.ChannelMessageId) (Evergreen.V408.UserSession.ToBeFilledInByBackend LoadedMatch)
    | LocalChange_Go (Evergreen.V408.Id.Id Evergreen.V408.Id.ChannelMessageId) Evergreen.V408.Go.LocalChange
    | LocalChange_WordSpellingGame (Evergreen.V408.Id.Id Evergreen.V408.Id.ChannelMessageId) Evergreen.V408.WordSpellingGame.LocalChange
    | LocalChange_SheepGame (Evergreen.V408.Id.Id Evergreen.V408.Id.ChannelMessageId) Evergreen.V408.SheepGame.LocalChange


type Game
    = GoModel_Game Evergreen.V408.Go.GameModel
    | WordSpellingGame_Game Evergreen.V408.WordSpellingGame.GameData
    | SheepGame_Game Evergreen.V408.SheepGame.GameData


type Setup
    = GameSelect
    | GoModel_Setup Evergreen.V408.Go.SetupModel
    | WordSpellingGame_Setup Evergreen.V408.WordSpellingGame.SetupModel
    | SheepGame_Setup Evergreen.V408.SheepGame.SetupModel


type alias Model =
    { startedGames : SeqDict.SeqDict (Evergreen.V408.Id.Id Evergreen.V408.Id.ChannelMessageId) Game
    , setup : Setup
    , sheepGameQuestionsCounter : Int
    , sheepGameSaveCounters : SeqDict.SeqDict ( Evergreen.V408.Id.Id Evergreen.V408.Id.ChannelMessageId, Evergreen.V408.SheepGame.Input ) Int
    }
