module Evergreen.V305.Game exposing (..)

import Array
import Evergreen.V305.Go
import Evergreen.V305.Id
import Evergreen.V305.Message
import Evergreen.V305.SecretId
import Evergreen.V305.UserSession
import Evergreen.V305.WordSpellingGame
import SeqDict


type Msg
    = GoGameMsg Evergreen.V305.Go.GameMsg
    | GoSetupMsg Evergreen.V305.Go.SetupMsg
    | WordSpellingGameMsg Evergreen.V305.WordSpellingGame.GameMsg
    | WordSpellingSetupMsg Evergreen.V305.WordSpellingGame.SetupMsg
    | PressedShareMatch (Evergreen.V305.Id.Id Evergreen.V305.Id.ChannelMessageId)
    | PressedCopyLink String
    | SelectedMatch (Evergreen.V305.Id.Id Evergreen.V305.Id.ChannelMessageId)
    | PressedReset
    | PressedSelectGame Evergreen.V305.Message.GameType
    | NoOpMsg


type FrontendGameData
    = FrontendGameData_Go Evergreen.V305.Go.ValidatedSetup (Array.Array Evergreen.V305.Go.ActionWithTime) Evergreen.V305.Go.Shared
    | FrontendGameData_WordSpellingGame Evergreen.V305.WordSpellingGame.ValidatedSetup (Array.Array Evergreen.V305.WordSpellingGame.ActionWithTime) Evergreen.V305.WordSpellingGame.Shared


type MatchData
    = MatchData
        { data : FrontendGameData
        , publicLink : Maybe (Evergreen.V305.SecretId.SecretId Evergreen.V305.Id.GamePublicId)
        }


type LocalChange
    = CreatePublicLink (Evergreen.V305.Id.Id Evergreen.V305.Id.ChannelMessageId) (Evergreen.V305.UserSession.ToBeFilledInByBackend (Evergreen.V305.SecretId.SecretId Evergreen.V305.Id.GamePublicId))
    | LocalChange_Go (Evergreen.V305.Id.Id Evergreen.V305.Id.ChannelMessageId) Evergreen.V305.Go.LocalChange
    | LocalChange_WordSpellingGame (Evergreen.V305.Id.Id Evergreen.V305.Id.ChannelMessageId) Evergreen.V305.WordSpellingGame.LocalChange


type Game
    = GoModel_Game Evergreen.V305.Go.GameModel
    | WordSpellingGame_Game Evergreen.V305.WordSpellingGame.GameData


type Setup
    = GameSelect
    | GoModel_Setup Evergreen.V305.Go.SetupModel
    | WordSpellingGame_Setup Evergreen.V305.WordSpellingGame.SetupModel


type alias Model =
    { startedGames : SeqDict.SeqDict (Evergreen.V305.Id.Id Evergreen.V305.Id.ChannelMessageId) Game
    , setup : Setup
    }


type BackendGameData
    = GameData_Go Evergreen.V305.Go.ValidatedSetup (Array.Array Evergreen.V305.Go.ActionWithTime)
    | GameData_WordSpellingGame Evergreen.V305.WordSpellingGame.ValidatedSetup (Array.Array Evergreen.V305.WordSpellingGame.ActionWithTime) Evergreen.V305.WordSpellingGame.Shared
