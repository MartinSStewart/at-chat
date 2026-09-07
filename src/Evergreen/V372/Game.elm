module Evergreen.V372.Game exposing (..)

import Array
import Evergreen.V372.Go
import Evergreen.V372.Id
import Evergreen.V372.Message
import Evergreen.V372.SecretId
import Evergreen.V372.SheepGame
import Evergreen.V372.UserSession
import Evergreen.V372.WordSpellingGame
import SeqDict


type Msg
    = GoGameMsg Evergreen.V372.Go.GameMsg
    | GoSetupMsg Evergreen.V372.Go.SetupMsg
    | WordSpellingGameMsg Evergreen.V372.WordSpellingGame.GameMsg
    | WordSpellingSetupMsg Evergreen.V372.WordSpellingGame.SetupMsg
    | SheepGameMsg Evergreen.V372.SheepGame.GameMsg
    | SheepSetupMsg Evergreen.V372.SheepGame.SetupMsg
    | PressedShareMatch (Evergreen.V372.Id.Id Evergreen.V372.Id.ChannelMessageId)
    | PressedCopyLink String
    | SelectedMatch (Evergreen.V372.Id.Id Evergreen.V372.Id.ChannelMessageId)
    | PressedReset
    | PressedSelectGame Evergreen.V372.Message.GameType
    | CheckedSheepGameQuestionsDebounce Int
    | CheckedSheepGameSaveDebounce (Evergreen.V372.Id.Id Evergreen.V372.Id.ChannelMessageId) Evergreen.V372.SheepGame.Input Int
    | NoOpMsg


type FrontendGameData
    = FrontendGameData_Go Evergreen.V372.Go.ValidatedSetup (Array.Array Evergreen.V372.Go.ActionWithTime) Evergreen.V372.Go.Shared
    | FrontendGameData_WordSpellingGame Evergreen.V372.WordSpellingGame.ValidatedSetup (Array.Array Evergreen.V372.WordSpellingGame.ActionWithTime) Evergreen.V372.WordSpellingGame.Shared
    | FrontendGameData_SheepGame Evergreen.V372.SheepGame.ValidatedSetup (Array.Array Evergreen.V372.SheepGame.ActionWithTime) Evergreen.V372.SheepGame.Shared


type MatchData
    = MatchData
        { data : FrontendGameData
        , publicLink : Maybe (Evergreen.V372.SecretId.SecretId Evergreen.V372.Id.GamePublicId)
        }
    | MatchNotLoaded Evergreen.V372.Message.GameType


type BackendGameData
    = GameData_Go Evergreen.V372.Go.ValidatedSetup (Array.Array Evergreen.V372.Go.ActionWithTime)
    | GameData_WordSpellingGame Evergreen.V372.WordSpellingGame.ValidatedSetup (Array.Array Evergreen.V372.WordSpellingGame.ActionWithTime) Evergreen.V372.WordSpellingGame.Shared
    | GameData_SheepGame Evergreen.V372.SheepGame.ValidatedSetup (Array.Array Evergreen.V372.SheepGame.ActionWithTime) Evergreen.V372.SheepGame.Shared


type alias LoadedMatch =
    { gameData : BackendGameData
    , publicLink : Maybe (Evergreen.V372.SecretId.SecretId Evergreen.V372.Id.GamePublicId)
    }


type LocalChange
    = CreatePublicLink (Evergreen.V372.Id.Id Evergreen.V372.Id.ChannelMessageId) (Evergreen.V372.UserSession.ToBeFilledInByBackend (Evergreen.V372.SecretId.SecretId Evergreen.V372.Id.GamePublicId))
    | LoadMatch (Evergreen.V372.Id.Id Evergreen.V372.Id.ChannelMessageId) (Evergreen.V372.UserSession.ToBeFilledInByBackend LoadedMatch)
    | LocalChange_Go (Evergreen.V372.Id.Id Evergreen.V372.Id.ChannelMessageId) Evergreen.V372.Go.LocalChange
    | LocalChange_WordSpellingGame (Evergreen.V372.Id.Id Evergreen.V372.Id.ChannelMessageId) Evergreen.V372.WordSpellingGame.LocalChange
    | LocalChange_SheepGame (Evergreen.V372.Id.Id Evergreen.V372.Id.ChannelMessageId) Evergreen.V372.SheepGame.LocalChange


type Game
    = GoModel_Game Evergreen.V372.Go.GameModel
    | WordSpellingGame_Game Evergreen.V372.WordSpellingGame.GameData
    | SheepGame_Game Evergreen.V372.SheepGame.GameData


type Setup
    = GameSelect
    | GoModel_Setup Evergreen.V372.Go.SetupModel
    | WordSpellingGame_Setup Evergreen.V372.WordSpellingGame.SetupModel
    | SheepGame_Setup Evergreen.V372.SheepGame.SetupModel


type alias Model =
    { startedGames : SeqDict.SeqDict (Evergreen.V372.Id.Id Evergreen.V372.Id.ChannelMessageId) Game
    , setup : Setup
    , sheepGameQuestionsCounter : Int
    , sheepGameSaveCounters : SeqDict.SeqDict ( Evergreen.V372.Id.Id Evergreen.V372.Id.ChannelMessageId, Evergreen.V372.SheepGame.Input ) Int
    }
