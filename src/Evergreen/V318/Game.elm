module Evergreen.V318.Game exposing (..)

import Array
import Evergreen.V318.Go
import Evergreen.V318.Id
import Evergreen.V318.Message
import Evergreen.V318.SecretId
import Evergreen.V318.UserSession
import Evergreen.V318.WordSpellingGame
import SeqDict


type Msg
    = GoGameMsg Evergreen.V318.Go.GameMsg
    | GoSetupMsg Evergreen.V318.Go.SetupMsg
    | WordSpellingGameMsg Evergreen.V318.WordSpellingGame.GameMsg
    | WordSpellingSetupMsg Evergreen.V318.WordSpellingGame.SetupMsg
    | PressedShareMatch (Evergreen.V318.Id.Id Evergreen.V318.Id.ChannelMessageId)
    | PressedCopyLink String
    | SelectedMatch (Evergreen.V318.Id.Id Evergreen.V318.Id.ChannelMessageId)
    | PressedReset
    | PressedSelectGame Evergreen.V318.Message.GameType
    | NoOpMsg


type FrontendGameData
    = FrontendGameData_Go Evergreen.V318.Go.ValidatedSetup (Array.Array Evergreen.V318.Go.ActionWithTime) Evergreen.V318.Go.Shared
    | FrontendGameData_WordSpellingGame Evergreen.V318.WordSpellingGame.ValidatedSetup (Array.Array Evergreen.V318.WordSpellingGame.ActionWithTime) Evergreen.V318.WordSpellingGame.Shared


type MatchData
    = MatchData
        { data : FrontendGameData
        , publicLink : Maybe (Evergreen.V318.SecretId.SecretId Evergreen.V318.Id.GamePublicId)
        }


type LocalChange
    = CreatePublicLink (Evergreen.V318.Id.Id Evergreen.V318.Id.ChannelMessageId) (Evergreen.V318.UserSession.ToBeFilledInByBackend (Evergreen.V318.SecretId.SecretId Evergreen.V318.Id.GamePublicId))
    | LocalChange_Go (Evergreen.V318.Id.Id Evergreen.V318.Id.ChannelMessageId) Evergreen.V318.Go.LocalChange
    | LocalChange_WordSpellingGame (Evergreen.V318.Id.Id Evergreen.V318.Id.ChannelMessageId) Evergreen.V318.WordSpellingGame.LocalChange


type Game
    = GoModel_Game Evergreen.V318.Go.GameModel
    | WordSpellingGame_Game Evergreen.V318.WordSpellingGame.GameData


type Setup
    = GameSelect
    | GoModel_Setup Evergreen.V318.Go.SetupModel
    | WordSpellingGame_Setup Evergreen.V318.WordSpellingGame.SetupModel


type alias Model =
    { startedGames : SeqDict.SeqDict (Evergreen.V318.Id.Id Evergreen.V318.Id.ChannelMessageId) Game
    , setup : Setup
    }


type BackendGameData
    = GameData_Go Evergreen.V318.Go.ValidatedSetup (Array.Array Evergreen.V318.Go.ActionWithTime)
    | GameData_WordSpellingGame Evergreen.V318.WordSpellingGame.ValidatedSetup (Array.Array Evergreen.V318.WordSpellingGame.ActionWithTime) Evergreen.V318.WordSpellingGame.Shared
