module Evergreen.V419.Game exposing (..)

import Array
import Evergreen.V419.Go
import Evergreen.V419.Id
import Evergreen.V419.Message
import Evergreen.V419.SecretId
import Evergreen.V419.SheepGame
import Evergreen.V419.UserSession
import Evergreen.V419.WordSpellingGame
import SeqDict


type Msg
    = GoGameMsg Evergreen.V419.Go.GameMsg
    | GoSetupMsg Evergreen.V419.Go.SetupMsg
    | WordSpellingGameMsg Evergreen.V419.WordSpellingGame.GameMsg
    | WordSpellingSetupMsg Evergreen.V419.WordSpellingGame.SetupMsg
    | SheepGameMsg Evergreen.V419.SheepGame.GameMsg
    | SheepSetupMsg Evergreen.V419.SheepGame.SetupMsg
    | PressedShareMatch (Evergreen.V419.Id.Id Evergreen.V419.Id.ChannelMessageId)
    | PressedCopyLink String
    | SelectedMatch (Evergreen.V419.Id.Id Evergreen.V419.Id.ChannelMessageId)
    | PressedReset
    | PressedSelectGame Evergreen.V419.Message.GameType
    | NoOpMsg


type FrontendGameData
    = FrontendGameData_Go Evergreen.V419.Go.ValidatedSetup (Array.Array Evergreen.V419.Go.ActionWithTime) Evergreen.V419.Go.Shared
    | FrontendGameData_WordSpellingGame Evergreen.V419.WordSpellingGame.ValidatedSetup (Array.Array Evergreen.V419.WordSpellingGame.ActionWithTime) Evergreen.V419.WordSpellingGame.Shared
    | FrontendGameData_SheepGame Evergreen.V419.SheepGame.ValidatedSetup (Array.Array Evergreen.V419.SheepGame.ActionWithTime) Evergreen.V419.SheepGame.Shared


type MatchData
    = MatchData
        { data : FrontendGameData
        , publicLink : Maybe (Evergreen.V419.SecretId.SecretId Evergreen.V419.Id.GamePublicId)
        }
    | MatchNotLoaded Evergreen.V419.Message.GameType


type BackendGameData
    = GameData_Go Evergreen.V419.Go.ValidatedSetup (Array.Array Evergreen.V419.Go.ActionWithTime)
    | GameData_WordSpellingGame Evergreen.V419.WordSpellingGame.ValidatedSetup (Array.Array Evergreen.V419.WordSpellingGame.ActionWithTime) Evergreen.V419.WordSpellingGame.Shared
    | GameData_SheepGame Evergreen.V419.SheepGame.ValidatedSetup (Array.Array Evergreen.V419.SheepGame.ActionWithTime) Evergreen.V419.SheepGame.Shared


type alias LoadedMatch =
    { gameData : BackendGameData
    , publicLink : Maybe (Evergreen.V419.SecretId.SecretId Evergreen.V419.Id.GamePublicId)
    }


type LocalChange
    = CreatePublicLink (Evergreen.V419.Id.Id Evergreen.V419.Id.ChannelMessageId) (Evergreen.V419.UserSession.ToBeFilledInByBackend (Evergreen.V419.SecretId.SecretId Evergreen.V419.Id.GamePublicId))
    | LoadMatch (Evergreen.V419.Id.Id Evergreen.V419.Id.ChannelMessageId) (Evergreen.V419.UserSession.ToBeFilledInByBackend LoadedMatch)
    | LocalChange_Go (Evergreen.V419.Id.Id Evergreen.V419.Id.ChannelMessageId) Evergreen.V419.Go.LocalChange
    | LocalChange_WordSpellingGame (Evergreen.V419.Id.Id Evergreen.V419.Id.ChannelMessageId) Evergreen.V419.WordSpellingGame.LocalChange
    | LocalChange_SheepGame (Evergreen.V419.Id.Id Evergreen.V419.Id.ChannelMessageId) Evergreen.V419.SheepGame.LocalChange


type Game
    = GoModel_Game Evergreen.V419.Go.GameModel
    | WordSpellingGame_Game Evergreen.V419.WordSpellingGame.GameData
    | SheepGame_Game Evergreen.V419.SheepGame.GameData


type Setup
    = GameSelect
    | GoModel_Setup Evergreen.V419.Go.SetupModel
    | WordSpellingGame_Setup Evergreen.V419.WordSpellingGame.SetupModel
    | SheepGame_Setup Evergreen.V419.SheepGame.SetupModel


type alias Model =
    { startedGames : SeqDict.SeqDict (Evergreen.V419.Id.Id Evergreen.V419.Id.ChannelMessageId) Game
    , setup : Setup
    , sheepGameQuestionsCounter : Int
    , sheepGameSaveCounters : SeqDict.SeqDict ( Evergreen.V419.Id.Id Evergreen.V419.Id.ChannelMessageId, Evergreen.V419.SheepGame.Input ) Int
    }
