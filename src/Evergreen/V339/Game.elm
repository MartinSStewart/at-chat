module Evergreen.V339.Game exposing (..)

import Array
import Evergreen.V339.Go
import Evergreen.V339.Id
import Evergreen.V339.Message
import Evergreen.V339.SecretId
import Evergreen.V339.UserSession
import Evergreen.V339.WordSpellingGame
import SeqDict


type Msg
    = GoGameMsg Evergreen.V339.Go.GameMsg
    | GoSetupMsg Evergreen.V339.Go.SetupMsg
    | WordSpellingGameMsg Evergreen.V339.WordSpellingGame.GameMsg
    | WordSpellingSetupMsg Evergreen.V339.WordSpellingGame.SetupMsg
    | PressedShareMatch (Evergreen.V339.Id.Id Evergreen.V339.Id.ChannelMessageId)
    | PressedCopyLink String
    | SelectedMatch (Evergreen.V339.Id.Id Evergreen.V339.Id.ChannelMessageId)
    | PressedReset
    | PressedSelectGame Evergreen.V339.Message.GameType
    | NoOpMsg


type FrontendGameData
    = FrontendGameData_Go Evergreen.V339.Go.ValidatedSetup (Array.Array Evergreen.V339.Go.ActionWithTime) Evergreen.V339.Go.Shared
    | FrontendGameData_WordSpellingGame Evergreen.V339.WordSpellingGame.ValidatedSetup (Array.Array Evergreen.V339.WordSpellingGame.ActionWithTime) Evergreen.V339.WordSpellingGame.Shared


type MatchData
    = MatchData
        { data : FrontendGameData
        , publicLink : Maybe (Evergreen.V339.SecretId.SecretId Evergreen.V339.Id.GamePublicId)
        }


type LocalChange
    = CreatePublicLink (Evergreen.V339.Id.Id Evergreen.V339.Id.ChannelMessageId) (Evergreen.V339.UserSession.ToBeFilledInByBackend (Evergreen.V339.SecretId.SecretId Evergreen.V339.Id.GamePublicId))
    | LocalChange_Go (Evergreen.V339.Id.Id Evergreen.V339.Id.ChannelMessageId) Evergreen.V339.Go.LocalChange
    | LocalChange_WordSpellingGame (Evergreen.V339.Id.Id Evergreen.V339.Id.ChannelMessageId) Evergreen.V339.WordSpellingGame.LocalChange


type Game
    = GoModel_Game Evergreen.V339.Go.GameModel
    | WordSpellingGame_Game Evergreen.V339.WordSpellingGame.GameData


type Setup
    = GameSelect
    | GoModel_Setup Evergreen.V339.Go.SetupModel
    | WordSpellingGame_Setup Evergreen.V339.WordSpellingGame.SetupModel


type alias Model =
    { startedGames : SeqDict.SeqDict (Evergreen.V339.Id.Id Evergreen.V339.Id.ChannelMessageId) Game
    , setup : Setup
    }


type BackendGameData
    = GameData_Go Evergreen.V339.Go.ValidatedSetup (Array.Array Evergreen.V339.Go.ActionWithTime)
    | GameData_WordSpellingGame Evergreen.V339.WordSpellingGame.ValidatedSetup (Array.Array Evergreen.V339.WordSpellingGame.ActionWithTime) Evergreen.V339.WordSpellingGame.Shared
