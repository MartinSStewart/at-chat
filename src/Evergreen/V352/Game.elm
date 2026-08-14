module Evergreen.V352.Game exposing (..)

import Array
import Evergreen.V352.Go
import Evergreen.V352.Id
import Evergreen.V352.Message
import Evergreen.V352.SecretId
import Evergreen.V352.UserSession
import Evergreen.V352.WordSpellingGame
import SeqDict


type Msg
    = GoGameMsg Evergreen.V352.Go.GameMsg
    | GoSetupMsg Evergreen.V352.Go.SetupMsg
    | WordSpellingGameMsg Evergreen.V352.WordSpellingGame.GameMsg
    | WordSpellingSetupMsg Evergreen.V352.WordSpellingGame.SetupMsg
    | PressedShareMatch (Evergreen.V352.Id.Id Evergreen.V352.Id.ChannelMessageId)
    | PressedCopyLink String
    | SelectedMatch (Evergreen.V352.Id.Id Evergreen.V352.Id.ChannelMessageId)
    | PressedReset
    | PressedSelectGame Evergreen.V352.Message.GameType
    | NoOpMsg


type FrontendGameData
    = FrontendGameData_Go Evergreen.V352.Go.ValidatedSetup (Array.Array Evergreen.V352.Go.ActionWithTime) Evergreen.V352.Go.Shared
    | FrontendGameData_WordSpellingGame Evergreen.V352.WordSpellingGame.ValidatedSetup (Array.Array Evergreen.V352.WordSpellingGame.ActionWithTime) Evergreen.V352.WordSpellingGame.Shared


type MatchData
    = MatchData
        { data : FrontendGameData
        , publicLink : Maybe (Evergreen.V352.SecretId.SecretId Evergreen.V352.Id.GamePublicId)
        }


type LocalChange
    = CreatePublicLink (Evergreen.V352.Id.Id Evergreen.V352.Id.ChannelMessageId) (Evergreen.V352.UserSession.ToBeFilledInByBackend (Evergreen.V352.SecretId.SecretId Evergreen.V352.Id.GamePublicId))
    | LocalChange_Go (Evergreen.V352.Id.Id Evergreen.V352.Id.ChannelMessageId) Evergreen.V352.Go.LocalChange
    | LocalChange_WordSpellingGame (Evergreen.V352.Id.Id Evergreen.V352.Id.ChannelMessageId) Evergreen.V352.WordSpellingGame.LocalChange


type Game
    = GoModel_Game Evergreen.V352.Go.GameModel
    | WordSpellingGame_Game Evergreen.V352.WordSpellingGame.GameData


type Setup
    = GameSelect
    | GoModel_Setup Evergreen.V352.Go.SetupModel
    | WordSpellingGame_Setup Evergreen.V352.WordSpellingGame.SetupModel


type alias Model =
    { startedGames : SeqDict.SeqDict (Evergreen.V352.Id.Id Evergreen.V352.Id.ChannelMessageId) Game
    , setup : Setup
    }


type BackendGameData
    = GameData_Go Evergreen.V352.Go.ValidatedSetup (Array.Array Evergreen.V352.Go.ActionWithTime)
    | GameData_WordSpellingGame Evergreen.V352.WordSpellingGame.ValidatedSetup (Array.Array Evergreen.V352.WordSpellingGame.ActionWithTime) Evergreen.V352.WordSpellingGame.Shared
