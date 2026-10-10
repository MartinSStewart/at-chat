module Evergreen.V402.Game exposing (..)

import Array
import Evergreen.V402.Go
import Evergreen.V402.Id
import Evergreen.V402.Message
import Evergreen.V402.SecretId
import Evergreen.V402.SheepGame
import Evergreen.V402.UserSession
import Evergreen.V402.WordSpellingGame
import SeqDict


type Msg
    = GoGameMsg Evergreen.V402.Go.GameMsg
    | GoSetupMsg Evergreen.V402.Go.SetupMsg
    | WordSpellingGameMsg Evergreen.V402.WordSpellingGame.GameMsg
    | WordSpellingSetupMsg Evergreen.V402.WordSpellingGame.SetupMsg
    | SheepGameMsg Evergreen.V402.SheepGame.GameMsg
    | SheepSetupMsg Evergreen.V402.SheepGame.SetupMsg
    | PressedShareMatch (Evergreen.V402.Id.Id Evergreen.V402.Id.ChannelMessageId)
    | PressedCopyLink String
    | SelectedMatch (Evergreen.V402.Id.Id Evergreen.V402.Id.ChannelMessageId)
    | PressedReset
    | PressedSelectGame Evergreen.V402.Message.GameType
    | NoOpMsg


type FrontendGameData
    = FrontendGameData_Go Evergreen.V402.Go.ValidatedSetup (Array.Array Evergreen.V402.Go.ActionWithTime) Evergreen.V402.Go.Shared
    | FrontendGameData_WordSpellingGame Evergreen.V402.WordSpellingGame.ValidatedSetup (Array.Array Evergreen.V402.WordSpellingGame.ActionWithTime) Evergreen.V402.WordSpellingGame.Shared
    | FrontendGameData_SheepGame Evergreen.V402.SheepGame.ValidatedSetup (Array.Array Evergreen.V402.SheepGame.ActionWithTime) Evergreen.V402.SheepGame.Shared


type MatchData
    = MatchData
        { data : FrontendGameData
        , publicLink : Maybe (Evergreen.V402.SecretId.SecretId Evergreen.V402.Id.GamePublicId)
        }
    | MatchNotLoaded Evergreen.V402.Message.GameType


type BackendGameData
    = GameData_Go Evergreen.V402.Go.ValidatedSetup (Array.Array Evergreen.V402.Go.ActionWithTime)
    | GameData_WordSpellingGame Evergreen.V402.WordSpellingGame.ValidatedSetup (Array.Array Evergreen.V402.WordSpellingGame.ActionWithTime) Evergreen.V402.WordSpellingGame.Shared
    | GameData_SheepGame Evergreen.V402.SheepGame.ValidatedSetup (Array.Array Evergreen.V402.SheepGame.ActionWithTime) Evergreen.V402.SheepGame.Shared


type alias LoadedMatch =
    { gameData : BackendGameData
    , publicLink : Maybe (Evergreen.V402.SecretId.SecretId Evergreen.V402.Id.GamePublicId)
    }


type LocalChange
    = CreatePublicLink (Evergreen.V402.Id.Id Evergreen.V402.Id.ChannelMessageId) (Evergreen.V402.UserSession.ToBeFilledInByBackend (Evergreen.V402.SecretId.SecretId Evergreen.V402.Id.GamePublicId))
    | LoadMatch (Evergreen.V402.Id.Id Evergreen.V402.Id.ChannelMessageId) (Evergreen.V402.UserSession.ToBeFilledInByBackend LoadedMatch)
    | LocalChange_Go (Evergreen.V402.Id.Id Evergreen.V402.Id.ChannelMessageId) Evergreen.V402.Go.LocalChange
    | LocalChange_WordSpellingGame (Evergreen.V402.Id.Id Evergreen.V402.Id.ChannelMessageId) Evergreen.V402.WordSpellingGame.LocalChange
    | LocalChange_SheepGame (Evergreen.V402.Id.Id Evergreen.V402.Id.ChannelMessageId) Evergreen.V402.SheepGame.LocalChange


type Game
    = GoModel_Game Evergreen.V402.Go.GameModel
    | WordSpellingGame_Game Evergreen.V402.WordSpellingGame.GameData
    | SheepGame_Game Evergreen.V402.SheepGame.GameData


type Setup
    = GameSelect
    | GoModel_Setup Evergreen.V402.Go.SetupModel
    | WordSpellingGame_Setup Evergreen.V402.WordSpellingGame.SetupModel
    | SheepGame_Setup Evergreen.V402.SheepGame.SetupModel


type alias Model =
    { startedGames : SeqDict.SeqDict (Evergreen.V402.Id.Id Evergreen.V402.Id.ChannelMessageId) Game
    , setup : Setup
    , sheepGameQuestionsCounter : Int
    , sheepGameSaveCounters : SeqDict.SeqDict ( Evergreen.V402.Id.Id Evergreen.V402.Id.ChannelMessageId, Evergreen.V402.SheepGame.Input ) Int
    }
