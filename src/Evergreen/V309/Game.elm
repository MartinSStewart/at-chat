module Evergreen.V309.Game exposing (..)

import Array
import Evergreen.V309.Go
import Evergreen.V309.Id
import Evergreen.V309.Message
import Evergreen.V309.SecretId
import Evergreen.V309.UserSession
import Evergreen.V309.WordSpellingGame
import SeqDict


type Msg
    = GoGameMsg Evergreen.V309.Go.GameMsg
    | GoSetupMsg Evergreen.V309.Go.SetupMsg
    | WordSpellingGameMsg Evergreen.V309.WordSpellingGame.GameMsg
    | WordSpellingSetupMsg Evergreen.V309.WordSpellingGame.SetupMsg
    | PressedShareMatch (Evergreen.V309.Id.Id Evergreen.V309.Id.ChannelMessageId)
    | PressedCopyLink String
    | SelectedMatch (Evergreen.V309.Id.Id Evergreen.V309.Id.ChannelMessageId)
    | PressedReset
    | PressedSelectGame Evergreen.V309.Message.GameType
    | NoOpMsg


type FrontendGameData
    = FrontendGameData_Go Evergreen.V309.Go.ValidatedSetup (Array.Array Evergreen.V309.Go.ActionWithTime) Evergreen.V309.Go.Shared
    | FrontendGameData_WordSpellingGame Evergreen.V309.WordSpellingGame.ValidatedSetup (Array.Array Evergreen.V309.WordSpellingGame.ActionWithTime) Evergreen.V309.WordSpellingGame.Shared


type MatchData
    = MatchData
        { data : FrontendGameData
        , publicLink : Maybe (Evergreen.V309.SecretId.SecretId Evergreen.V309.Id.GamePublicId)
        }


type LocalChange
    = CreatePublicLink (Evergreen.V309.Id.Id Evergreen.V309.Id.ChannelMessageId) (Evergreen.V309.UserSession.ToBeFilledInByBackend (Evergreen.V309.SecretId.SecretId Evergreen.V309.Id.GamePublicId))
    | LocalChange_Go (Evergreen.V309.Id.Id Evergreen.V309.Id.ChannelMessageId) Evergreen.V309.Go.LocalChange
    | LocalChange_WordSpellingGame (Evergreen.V309.Id.Id Evergreen.V309.Id.ChannelMessageId) Evergreen.V309.WordSpellingGame.LocalChange


type Game
    = GoModel_Game Evergreen.V309.Go.GameModel
    | WordSpellingGame_Game Evergreen.V309.WordSpellingGame.GameData


type Setup
    = GameSelect
    | GoModel_Setup Evergreen.V309.Go.SetupModel
    | WordSpellingGame_Setup Evergreen.V309.WordSpellingGame.SetupModel


type alias Model =
    { startedGames : SeqDict.SeqDict (Evergreen.V309.Id.Id Evergreen.V309.Id.ChannelMessageId) Game
    , setup : Setup
    }


type BackendGameData
    = GameData_Go Evergreen.V309.Go.ValidatedSetup (Array.Array Evergreen.V309.Go.ActionWithTime)
    | GameData_WordSpellingGame Evergreen.V309.WordSpellingGame.ValidatedSetup (Array.Array Evergreen.V309.WordSpellingGame.ActionWithTime) Evergreen.V309.WordSpellingGame.Shared
