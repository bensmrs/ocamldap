(* Flow control primitives

  This library is free software; you can redistribute it and/or
  modify it under the terms of the GNU Lesser General Public
  License as published by the Free Software Foundation; either
  version 2.1 of the License, or (at your option) any later version.

  Copyright (C) 2022 Benjamin Somers

  This library is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
  Lesser General Public License for more details.

  You should have received a copy of the GNU Lesser General Public
  License along with this library; if not, write to the Free Software
  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
*)

type op = Read | Write

type ld_socket = Ssl of Ssl.socket
               | Plain of Unix.file_descr

let close = function
  | Ssl sock ->
      Unix.set_nonblock (Ssl.file_descr_of_socket sock);
      Ssl.shutdown sock
  | Plain fd -> Unix.close fd

let wrap op timeout sock buf off len =
  let (s, f, read_s, write_s) = match sock with
    | Ssl s ->
        let fd = Ssl.file_descr_of_socket s in begin
        match op with
        | Read -> (fd, Ssl.read s, [fd], [])
        | Write -> (fd, Ssl.write s, [], [fd]) end
    | Plain fd -> begin
        match op with
        | Read -> (fd, Unix.read fd, [fd], [])
        | Write -> (fd, Unix.write fd, [], [fd]) end in
  let (read_ok, write_ok, _) = Unix.select read_s write_s [] timeout in
  match Unix.getsockopt_error s with
  | Some err -> raise (Unix.Unix_error (err, "wrap", ""))
  | None ->
      if read_ok @ write_ok <> [s] then
        raise (Unix.Unix_error (ETIMEDOUT, "wrap", ""));
      (try f buf off len with
       | Unix.Unix_error (EAGAIN, _, _)
       | Unix.Unix_error (EWOULDBLOCK, _, _) -> 0)

let connect mech timeout sock addr =
  Unix.set_nonblock sock;
  (try Unix.connect sock addr
   with Unix.Unix_error (EINPROGRESS, _, _) -> ());
  let (_, ok, _) = Unix.select [] [sock] [] timeout in
  match Unix.getsockopt_error sock with
    | Some err ->
        raise (Unix.Unix_error (err, "open_con", ""))
    | None ->
        if ok <> [sock] then raise (Unix.Unix_error (ETIMEDOUT, "connect", ""));
        (match mech with
           `PLAIN -> Plain sock
         | `SSL ->
             let context = Ssl.create_context SSLv23 Client_context
             in
               Unix.clear_nonblock sock;
               let ssl = Ssl.embed_socket sock context in
               Ssl.connect ssl;
               Ssl ssl)
