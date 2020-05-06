codeunit 59998 "ICE Consistency CU"
{
    SingleInstance = true;

    trigger OnRun()
    var
        Item: Record Item;
    begin
        if SaveEntries then begin
            Page.RunModal(0, TempGLEntry);
            SaveEntries := false;
        end else begin
            SaveEntries := true;
            Message('GL Entries are being collected');
        end;

    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Gen. Jnl.-Post Line", 'OnAfterInsertGlobalGLEntry', '', false, false)]
    procedure InsertGL(var GLEntry: Record "G/L Entry")
    begin
        if SaveEntries then begin
            TempGLEntry := GLEntry;
            if not TempGLEntry.Insert() then begin
                TempGLEntry.DeleteAll();
                TempGLEntry.Insert();
            end;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales-Post", 'OnBeforePostSalesDoc', '', false, false)]
    local procedure SalesPostPrepare(var SalesHeader: Record "Sales Header")
    begin
        SaveEntries := ((SalesHeader."Sell-to Customer No." = '0000000000') and (CopyStr(SalesHeader."External Document No.", 1, 3) = 'SP-'));
        TempGLEntry.DeleteAll();
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales-Post", 'OnBeforePostCustomerEntry', '', false, false)]
    local procedure SalesPostCleanup(var GenJnlLine: Record "Gen. Journal Line"; SalesHeader: Record "Sales Header")
    var
        PostingSum: Decimal;
        MaxNeg: Decimal;
        MaxPos: Decimal;
        MaxNegEntry: Record "G/L Entry" temporary;
        MaxPosEntry: record "G/L Entry" temporary;
        GLEntry: Record "G/L Entry";
        CurrencySum: Decimal;
    begin
        if SaveEntries then begin
            PostingSum := 0;
            if TempGLEntry.FindSet() then
                repeat
                    PostingSum := PostingSum + TempGLEntry.Amount;
                until TempGLEntry.Next() = 0;
            if (PostingSum <> -GenJnlLine."Amount (LCY)") and (Abs(PostingSum + GenJnlLine."Amount (LCY)") < 0.5) then
                GenJnlLine.Validate("Amount (LCY)", -PostingSum);
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Purch.-Post", 'OnBeforePostPurchaseDoc', '', false, false)]
    local procedure PurchPostPrepare(var PurchaseHeader: Record "Purchase Header")
    begin
        SaveEntries := (UserId = 'BLUELAGOON\SVEINN.RUEDENET');
        TempGLEntry.DeleteAll();
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Purch.-Post", 'OnBeforePostVendorEntry', '', false, false)]
    local procedure PurchPostCleanup(var GenJnlLine: Record "Gen. Journal Line"; var PurchHeader: Record "Purchase Header"; var TotalPurchLine: Record "Purchase Line"; var TotalPurchLineLCY: Record "Purchase Line")
    var
        PostingSum: Decimal;
        MaxNeg: Decimal;
        MaxPos: Decimal;
        MaxNegEntry: Record "G/L Entry" temporary;
        MaxPosEntry: Record "G/L Entry" temporary;
        GLEntry: Record "G/L Entry";
        CurrencySum: Decimal;
    begin
        if SaveEntries then begin
            PostingSum := 0;
            if TempGLEntry.FindSet() then
                repeat
                    PostingSum := PostingSum + TempGLEntry.Amount;
                until TempGLEntry.Next() = 0;
            if (PostingSum <> -GenJnlLine."Amount (LCY)") and (Abs(PostingSum + GenJnlLine."Amount (LCY)") <= 0.1) then
                GenJnlLine.Validate("Amount (LCY)", -PostingSum);
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Gen. Jnl.-Post Line", 'OnBeforeInsertGLEntryBuffer', '', false, false)]
    local procedure CU12Subscriber(var TempGLEntryBuf: Record "G/L Entry" temporary; var GenJournalLine: Record "Gen. Journal Line"; var BalanceCheckAmount: Decimal; var BalanceCheckAmount2: Decimal; var BalanceCheckAddCurrAmount: Decimal; var BalanceCheckAddCurrAmount2: Decimal; var NextEntryNo: Integer; var TotalAmount: Decimal; var TotalAddCurrAmount: Decimal)
    begin
        BalanceCheckAddCurrAmount := 0;
        BalanceCheckAmount2 := 0;
        Error(StrSubstNo('BalanceCheckAddCurrAmount: %1, BalanceCheckAmount2: %2', BalanceCheckAddCurrAmount, BalanceCheckAmount2));
    end;

    var
        TempGLEntry: Record "G/L Entry" temporary;
        SaveEntries: Boolean;
}