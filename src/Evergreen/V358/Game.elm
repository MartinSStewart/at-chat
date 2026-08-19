module Evergreen.V358.Game exposing (..)

import Array
import Evergreen.V358.Go
import Evergreen.V358.Id
import Evergreen.V358.Message
import Evergreen.V358.SecretId
import Evergreen.V358.SheepGame
import Evergreen.V358.UserSession
import Evergreen.V358.WordSpellingGame
import SeqDict


type Msg
    = GoGameMsg Evergreen.V358.Go.GameMsg
    | GoSetupMsg Evergreen.V358.Go.SetupMsg
    | WordSpellingGameMsg Evergreen.V358.WordSpellingGame.GameMsg
    | WordSpellingSetupMsg Evergreen.V358.WordSpellingGame.SetupMsg
    | SheepGameMsg Evergreen.V358.SheepGame.GameMsg
    | SheepSetupMsg Evergreen.V358.SheepGame.SetupMsg
    | PressedShareMatch (Evergreen.V358.Id.Id Evergreen.V358.Id.ChannelMessageId)
    | PressedCopyLink String
    | SelectedMatch (Evergreen.V358.Id.Id Evergreen.V358.Id.ChannelMessageId)
    | PressedReset
    | PressedSelectGame Evergreen.V358.Message.GameType
    | NoOpMsg


type FrontendGameData
    = FrontendGameData_Go Evergreen.V358.Go.ValidatedSetup (Array.Array Evergreen.V358.Go.ActionWithTime) Evergreen.V358.Go.Shared
    | FrontendGameData_WordSpellingGame Evergreen.V358.WordSpellingGame.ValidatedSetup (Array.Array Evergreen.V358.WordSpellingGame.ActionWithTime) Evergreen.V358.WordSpellingGame.Shared
    | FrontendGameData_SheepGame Evergreen.V358.SheepGame.ValidatedSetup (Array.Array Evergreen.V358.SheepGame.ActionWithTime) Evergreen.V358.SheepGame.Shared


type MatchData
    = MatchData
        { data : FrontendGameData
        , publicLink : Maybe (Evergreen.V358.SecretId.SecretId Evergreen.V358.Id.GamePublicId)
        }


type LocalChange
    = CreatePublicLink (Evergreen.V358.Id.Id Evergreen.V358.Id.ChannelMessageId) (Evergreen.V358.UserSession.ToBeFilledInByBackend (Evergreen.V358.SecretId.SecretId Evergreen.V358.Id.GamePublicId))
    | LocalChange_Go (Evergreen.V358.Id.Id Evergreen.V358.Id.ChannelMessageId) Evergreen.V358.Go.LocalChange
    | LocalChange_WordSpellingGame (Evergreen.V358.Id.Id Evergreen.V358.Id.ChannelMessageId) Evergreen.V358.WordSpellingGame.LocalChange
    | LocalChange_SheepGame (Evergreen.V358.Id.Id Evergreen.V358.Id.ChannelMessageId) Evergreen.V358.SheepGame.LocalChange


type Game
    = GoModel_Game Evergreen.V358.Go.GameModel
    | WordSpellingGame_Game Evergreen.V358.WordSpellingGame.GameData
    | SheepGame_Game Evergreen.V358.SheepGame.GameData


type Setup
    = GameSelect
    | GoModel_Setup Evergreen.V358.Go.SetupModel
    | WordSpellingGame_Setup Evergreen.V358.WordSpellingGame.SetupModel
    | SheepGame_Setup Evergreen.V358.SheepGame.SetupModel


type alias Model =
    { startedGames : SeqDict.SeqDict (Evergreen.V358.Id.Id Evergreen.V358.Id.ChannelMessageId) Game
    , setup : Setup
    }


type BackendGameData
    = GameData_Go Evergreen.V358.Go.ValidatedSetup (Array.Array Evergreen.V358.Go.ActionWithTime)
    | GameData_WordSpellingGame Evergreen.V358.WordSpellingGame.ValidatedSetup (Array.Array Evergreen.V358.WordSpellingGame.ActionWithTime) Evergreen.V358.WordSpellingGame.Shared
    | GameData_SheepGame Evergreen.V358.SheepGame.ValidatedSetup (Array.Array Evergreen.V358.SheepGame.ActionWithTime) Evergreen.V358.SheepGame.Shared
