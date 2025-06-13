const print = @import("std").debug.print;

const rows = 6;
const cols = 7;
const to_win = 4;
const symbols = "XO_";
// const moves = [_]usize{ 2, 1, 3, 4, 0, 6, 2, 5, 4, 2, 4, 3, 1, 2, 2, 2, 2, 1 };
const moves = [_]usize{ 0, 1, 2, 3, 0, 1, 2, 3, 0, 1, 2, 3, 3, 2, 1, 0 };
const board_size = rows * cols;

const Move = struct {
    player: u8, // 'X' or 'O'
    column: u8,
    turn: u8
};

// const history: [moves.len]Move = undefined;
var history: [moves.len]Move = @splat(.{.player = 0, .column = 0, .turn = 0});
// var some_integers: [100]i32 = undefined;


comptime { // <- Validates options at compile time as much as it can and raises compile errors
    if (rows < to_win) {
        // @compileError("\"rows\" can't be lesser than {}", .{ to_win });
        @compileError("\"rows\" can't be lesser than to_win");
    }
    if (cols < to_win) {
        // @compileError("\"cols\" can't be lesser than {}", .{ to_win });
        @compileError("\"cols\" can't be lesser than to_win");
    }
    if (to_win < 2) {
        @compileError("\"to_win\" can't be < 2!");
    }
    if (symbols.len != 3) {
        @compileError("\"symbols\" must contain exactly 3 values!");
    }
    if (symbols[0] == symbols[1] or symbols[0] == symbols[2] or symbols[1] == symbols[2]) {
        @compileError("\"symbols\" can't contain duplicate values!");
    }
    // if (moves.len < to_win * 2 - 1) {
    //     @compileError("\"to_win\" impossible to reach in number of provided moves!");
    // }
    // for (moves) |move| {
    //     if (move >= board_size) {
    //         @compileError("\"moves\" contain index too large for board size!");
    //     }
    // }
}

const Board: type = [rows][cols]u8;

pub fn draw_board(board: *const Board) void {
    print("Board:\n", .{});
    for (board) |r| { // <- notice you can count index from any arbitrary value 1..
        for (r, 1..) |tile, c| {
            const ending: u8 = if (c == cols) '\n' else ' '; // <= could be done better, just wanted to show it
            print("{c}{c}", .{ tile, ending });
        }
    }
    print("\n", .{});
}

pub fn check_winner(board: *const Board, changed_row: usize, changed_col: usize) bool {
    // const changed_row = change_at / cols;
    // const changed_col = change_at % cols;
    const placed_tile = board[changed_row][changed_col];
    // MATH MADNESS, NO INTERESTING LANGUAGE FATURES HERE
    horizontal: for (0..to_win) |check| {
        if (changed_col >= check and changed_col + to_win <= cols + check) {
            for (0..to_win) |offset| {
                if (board[changed_row][changed_col + offset - check] != placed_tile) {
                    continue :horizontal; // <- only interesting thing, outer loop continue
                }
            }
            print("Found horizontal!\n", .{});
            return true;
        }
    }
    vertical: for (0..to_win) |check| {
        if (changed_row >= check and changed_row + to_win <= rows + check) {
            for (0..to_win) |offset| {
                // if (board[changed_col - check * cols + offset * cols][changed_col] != placed_tile) {
                if (board[changed_row + offset - check][changed_col] != placed_tile) {
                    continue :vertical;
                }
            }
            print("Found vertical!\n", .{});
            return true;
        }
    }
    diagonal_1: for (0..to_win) |check| {
        if (changed_row >= check and changed_row + to_win <= rows + check and changed_col >= check and changed_col + to_win <= cols + check) {
            for (0..to_win) |offset| {
                if (board[changed_row + offset - check][changed_col + offset - check] != placed_tile) {
                    continue :diagonal_1;
                }
            }
            print("Found diagonal (top-left <==> bottom-right)!\n", .{});
            return true;
        }
    }
    diagonal_2: for (0..to_win) |check| {
        if (changed_row >= check and changed_row + to_win <= rows + check and changed_col + check + 1 >= to_win and changed_col + check < cols) {
            for (0..to_win) |offset| {
                if (board[changed_row + offset - check] [changed_col + check - offset] != placed_tile) {
                    continue :diagonal_2;
                }
            }
            print("Found diagonal (top-right <==> bottom-left)!\n", .{});
            return true;
        }
    }
    return false;
}

pub fn main() void {
    print("GAME STARTS", .{});
    var last_move = @as(usize, 0) -% 1; // <- really cool, basically sets to usize max value with underflow subtraction (there is also more general function in std for this)
    
    var board: Board = [1][cols]u8{[1]u8{symbols[2]} ** cols} ** rows; // <- populates board with "empty" symbol
    // [1]u8{symbols[2]}
    _ = &board;
    print("Board:\n {any}\n", .{board});
    print("Element = {}\n", .{board[0][1]});
    draw_board(&board);
    print("History:\n {any}\n", .{history});
    // print("History:\n {any}\n", .{history[0]});
    var history_test = [1]Move{.{ .player = 'X', .column = 1, .turn = 2}} ** 2; 
    _ = &history_test;
    print("History TEST:\n {any}\n", .{history_test});
    
    
    // for (history) |move| { // <- notice you can count index from any arbitrary value 1..
    //     print("{}", .{ move });
    // }
    
    for (0..board_size) |turn| {
        const current_player = symbols[turn % 2];
        print("Turn {}, player {c} on move:\n", .{ turn + 1, current_player });
        
        var ri: usize = rows - 1;
        last_move = floop: for (last_move +% 1..moves.len) |move| { // <- Zig for loop is expresion, also notice the overflow addition
            // if (board[moves[move]] == symbols[2]) {
            ri = rows - 1;
            while (ri >= 0): (ri -= 1) {
                if (board[ri][moves[move]] == symbols[2]) {
                    board[ri][moves[move]] = current_player;
                    break :floop move; // ri, moves[move] <- return value from loop expresion
                }
                if (ri == 0) {
                    break;
                }
            }
        } else return;// error.NotEnoughMovesProvided; // <- we ran out of moves
        // history[turn].turn = @intCast(turn);

        print("########################## {} : {}\n", .{ri, moves[last_move]});
        draw_board(&board);
        
        if (check_winner(&board, ri, moves[last_move])) {
            print("THE WINNER IS: {c}!\n", .{current_player});
            break; // <- implicitly its "break void;", which means expresion returned and "else" is ignored
        }

    } else print("IT'S A TIE!\n", .{}); // <- again loop is expresion, this trigers only if it does not return
    
    print("GAME OVER\n", .{});
    print("History:\n {any}\n", .{history});
}
