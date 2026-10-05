module Evergreen.V398.Game exposing (..)

import Array
import Evergreen.V398.Go
import Evergreen.V398.Id
import Evergreen.V398.Message
import Evergreen.V398.SecretId
import Evergreen.V398.SheepGame
import Evergreen.V398.UserSession
import Evergreen.V398.WordSpellingGame
import SeqDict


type Msg
    = GoGameMsg Evergreen.V398.Go.GameMsg
    | GoSetupMsg Evergreen.V398.Go.SetupMsg
    | WordSpellingGameMsg Evergreen.V398.WordSpellingGame.GameMsg
    | WordSpellingSetupMsg Evergreen.V398.WordSpellingGame.SetupMsg
    | SheepGameMsg Evergreen.V398.SheepGame.GameMsg
    | SheepSetupMsg Evergreen.V398.SheepGame.SetupMsg
    | PressedShareMatch (Evergreen.V398.Id.Id Evergreen.V398.Id.ChannelMessageId)
    | PressedCopyLink String
    | SelectedMatch (Evergreen.V398.Id.Id Evergreen.V398.Id.ChannelMessageId)
    | PressedReset
    | PressedSelectGame Evergreen.V398.Message.GameType
    | NoOpMsg


type FrontendGameData
    = FrontendGameData_Go Evergreen.V398.Go.ValidatedSetup (Array.Array Evergreen.V398.Go.ActionWithTime) Evergreen.V398.Go.Shared
    | FrontendGameData_WordSpellingGame Evergreen.V398.WordSpellingGame.ValidatedSetup (Array.Array Evergreen.V398.WordSpellingGame.ActionWithTime) Evergreen.V398.WordSpellingGame.Shared
    | FrontendGameData_SheepGame Evergreen.V398.SheepGame.ValidatedSetup (Array.Array Evergreen.V398.SheepGame.ActionWithTime) Evergreen.V398.SheepGame.Shared


type MatchData
    = MatchData
        { data : FrontendGameData
        , publicLink : Maybe (Evergreen.V398.SecretId.SecretId Evergreen.V398.Id.GamePublicId)
        }
    | MatchNotLoaded Evergreen.V398.Message.GameType


type BackendGameData
    = GameData_Go Evergreen.V398.Go.ValidatedSetup (Array.Array Evergreen.V398.Go.ActionWithTime)
    | GameData_WordSpellingGame Evergreen.V398.WordSpellingGame.ValidatedSetup (Array.Array Evergreen.V398.WordSpellingGame.ActionWithTime) Evergreen.V398.WordSpellingGame.Shared
    | GameData_SheepGame Evergreen.V398.SheepGame.ValidatedSetup (Array.Array Evergreen.V398.SheepGame.ActionWithTime) Evergreen.V398.SheepGame.Shared


type alias LoadedMatch =
    { gameData : BackendGameData
    , publicLink : Maybe (Evergreen.V398.SecretId.SecretId Evergreen.V398.Id.GamePublicId)
    }


type LocalChange
    = CreatePublicLink (Evergreen.V398.Id.Id Evergreen.V398.Id.ChannelMessageId) (Evergreen.V398.UserSession.ToBeFilledInByBackend (Evergreen.V398.SecretId.SecretId Evergreen.V398.Id.GamePublicId))
    | LoadMatch (Evergreen.V398.Id.Id Evergreen.V398.Id.ChannelMessageId) (Evergreen.V398.UserSession.ToBeFilledInByBackend LoadedMatch)
    | LocalChange_Go (Evergreen.V398.Id.Id Evergreen.V398.Id.ChannelMessageId) Evergreen.V398.Go.LocalChange
    | LocalChange_WordSpellingGame (Evergreen.V398.Id.Id Evergreen.V398.Id.ChannelMessageId) Evergreen.V398.WordSpellingGame.LocalChange
    | LocalChange_SheepGame (Evergreen.V398.Id.Id Evergreen.V398.Id.ChannelMessageId) Evergreen.V398.SheepGame.LocalChange


type Game
    = GoModel_Game Evergreen.V398.Go.GameModel
    | WordSpellingGame_Game Evergreen.V398.WordSpellingGame.GameData
    | SheepGame_Game Evergreen.V398.SheepGame.GameData


type Setup
    = GameSelect
    | GoModel_Setup Evergreen.V398.Go.SetupModel
    | WordSpellingGame_Setup Evergreen.V398.WordSpellingGame.SetupModel
    | SheepGame_Setup Evergreen.V398.SheepGame.SetupModel


type alias Model =
    { startedGames : SeqDict.SeqDict (Evergreen.V398.Id.Id Evergreen.V398.Id.ChannelMessageId) Game
    , setup : Setup
    , sheepGameQuestionsCounter : Int
    , sheepGameSaveCounters : SeqDict.SeqDict ( Evergreen.V398.Id.Id Evergreen.V398.Id.ChannelMessageId, Evergreen.V398.SheepGame.Input ) Int
    }
