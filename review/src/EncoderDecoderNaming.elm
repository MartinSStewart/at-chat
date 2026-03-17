module EncoderDecoderNaming exposing (rule)

{-| Enforces that encoder/decoder functions are named `encodeTypeName` and `decodeTypeName`
rather than `typeNameEncoder` and `typeNameDecoder`.
-}

import Elm.Syntax.Declaration exposing (Declaration(..))
import Elm.Syntax.Node as Node exposing (Node(..))
import Elm.Syntax.Signature exposing (Signature)
import Review.Fix as Fix
import Review.Rule as Rule exposing (Rule)


rule : Rule
rule =
    Rule.newModuleRuleSchema "EncoderDecoderNaming" ()
        |> Rule.withDeclarationEnterVisitor declarationVisitor
        |> Rule.fromModuleRuleSchema


declarationVisitor : Node Declaration -> () -> ( List (Rule.Error {}), () )
declarationVisitor (Node _ declaration) context =
    case declaration of
        FunctionDeclaration function ->
            let
                nameNode : Node String
                nameNode =
                    Node.value function.declaration |> .name

                name : String
                name =
                    Node.value nameNode

                signatureNameNode : Maybe (Node String)
                signatureNameNode =
                    function.signature
                        |> Maybe.map (\(Node _ sig) -> sig.name)
            in
            ( checkName nameNode signatureNameNode name, context )

        _ ->
            ( [], context )


checkName : Node String -> Maybe (Node String) -> String -> List (Rule.Error {})
checkName nameNode signatureNameNode name =
    if String.endsWith "Encoder" name && String.length name > 7 then
        makeError nameNode signatureNameNode name 7 "encode" "Encoders should be named `encodeTypeName` instead of `typeNameEncoder` for consistency."

    else if String.endsWith "Decoder" name && String.length name > 7 then
        makeError nameNode signatureNameNode name 7 "decode" "Decoders should be named `decodeTypeName` instead of `typeNameDecoder` for consistency."

    else if String.endsWith "Encode" name && String.length name > 6 then
        makeError nameNode signatureNameNode name 6 "encode" "Encoders should be named `encodeTypeName` instead of `typeNameEncode` for consistency."

    else if String.endsWith "Decode" name && String.length name > 6 then
        makeError nameNode signatureNameNode name 6 "decode" "Decoders should be named `decodeTypeName` instead of `typeNameDecode` for consistency."

    else
        []


makeError : Node String -> Maybe (Node String) -> String -> Int -> String -> String -> List (Rule.Error {})
makeError nameNode signatureNameNode name suffixLen prefix detail =
    let
        typeName : String
        typeName =
            String.dropRight suffixLen name

        suggested : String
        suggested =
            prefix ++ capitalize typeName

        signatureFix : List Fix.Fix
        signatureFix =
            case signatureNameNode of
                Just sigNameNode ->
                    [ Fix.replaceRangeBy (Node.range sigNameNode) suggested ]

                Nothing ->
                    []
    in
    [ Rule.errorWithFix
        { message = name ++ " should be named " ++ suggested
        , details = [ detail ]
        }
        (Node.range nameNode)
        (Fix.replaceRangeBy (Node.range nameNode) suggested :: signatureFix)
    ]


capitalize : String -> String
capitalize str =
    case String.uncons str of
        Just ( first, rest ) ->
            String.fromChar (Char.toUpper first) ++ rest

        Nothing ->
            str
