module Evergreen.V354.Game exposing (..)

import Array
import Evergreen.V354.Go
import Evergreen.V354.Id
import Evergreen.V354.Message
import Evergreen.V354.SecretId
import Evergreen.V354.SheepGame
import Evergreen.V354.UserSession
import Evergreen.V354.WordSpellingGame
import SeqDict


type Msg
    = GoGameMsg Evergreen.V354.Go.GameMsg
    | GoSetupMsg Evergreen.V354.Go.SetupMsg
    | WordSpellingGameMsg Evergreen.V354.WordSpellingGame.GameMsg
    | WordSpellingSetupMsg Evergreen.V354.WordSpellingGame.SetupMsg
    | SheepGameMsg Evergreen.V354.SheepGame.GameMsg
    | SheepSetupMsg Evergreen.V354.SheepGame.SetupMsg
    | PressedShareMatch (Evergreen.V354.Id.Id Evergreen.V354.Id.ChannelMessageId)
    | PressedCopyLink String
    | SelectedMatch (Evergreen.V354.Id.Id Evergreen.V354.Id.ChannelMessageId)
    | PressedReset
    | PressedSelectGame Evergreen.V354.Message.GameType
    | NoOpMsg


type FrontendGameData
    = FrontendGameData_Go Evergreen.V354.Go.ValidatedSetup (Array.Array Evergreen.V354.Go.ActionWithTime) Evergreen.V354.Go.Shared
    | FrontendGameData_WordSpellingGame Evergreen.V354.WordSpellingGame.ValidatedSetup (Array.Array Evergreen.V354.WordSpellingGame.ActionWithTime) Evergreen.V354.WordSpellingGame.Shared
    | FrontendGameData_SheepGame Evergreen.V354.SheepGame.ValidatedSetup (Array.Array Evergreen.V354.SheepGame.ActionWithTime) Evergreen.V354.SheepGame.Shared


type MatchData
    = MatchData
        { data : FrontendGameData
        , publicLink : Maybe (Evergreen.V354.SecretId.SecretId Evergreen.V354.Id.GamePublicId)
        }


type LocalChange
    = CreatePublicLink (Evergreen.V354.Id.Id Evergreen.V354.Id.ChannelMessageId) (Evergreen.V354.UserSession.ToBeFilledInByBackend (Evergreen.V354.SecretId.SecretId Evergreen.V354.Id.GamePublicId))
    | LocalChange_Go (Evergreen.V354.Id.Id Evergreen.V354.Id.ChannelMessageId) Evergreen.V354.Go.LocalChange
    | LocalChange_WordSpellingGame (Evergreen.V354.Id.Id Evergreen.V354.Id.ChannelMessageId) Evergreen.V354.WordSpellingGame.LocalChange
    | LocalChange_SheepGame (Evergreen.V354.Id.Id Evergreen.V354.Id.ChannelMessageId) Evergreen.V354.SheepGame.LocalChange


type Game
    = GoModel_Game Evergreen.V354.Go.GameModel
    | WordSpellingGame_Game Evergreen.V354.WordSpellingGame.GameData
    | SheepGame_Game Evergreen.V354.SheepGame.GameData


type Setup
    = GameSelect
    | GoModel_Setup Evergreen.V354.Go.SetupModel
    | WordSpellingGame_Setup Evergreen.V354.WordSpellingGame.SetupModel
    | SheepGame_Setup Evergreen.V354.SheepGame.SetupModel


type alias Model =
    { startedGames : SeqDict.SeqDict (Evergreen.V354.Id.Id Evergreen.V354.Id.ChannelMessageId) Game
    , setup : Setup
    }


type BackendGameData
    = GameData_Go Evergreen.V354.Go.ValidatedSetup (Array.Array Evergreen.V354.Go.ActionWithTime)
    | GameData_WordSpellingGame Evergreen.V354.WordSpellingGame.ValidatedSetup (Array.Array Evergreen.V354.WordSpellingGame.ActionWithTime) Evergreen.V354.WordSpellingGame.Shared
    | GameData_SheepGame Evergreen.V354.SheepGame.ValidatedSetup (Array.Array Evergreen.V354.SheepGame.ActionWithTime) Evergreen.V354.SheepGame.Shared
