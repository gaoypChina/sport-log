use proc_macro::TokenStream;

mod crud;
mod to_from_sql;
mod verification;
use crud::*;
use to_from_sql::*;
use verification::*;

#[proc_macro_derive(Create)]
pub fn create_derive(input: TokenStream) -> TokenStream {
    let ast = syn::parse(input).unwrap();
    impl_create(&ast)
}

#[proc_macro_derive(GetById)]
pub fn get_by_id_derive(input: TokenStream) -> TokenStream {
    let ast = syn::parse(input).unwrap();
    impl_get_by_id(&ast)
}

#[proc_macro_derive(GetAll)]
pub fn get_all_derive(input: TokenStream) -> TokenStream {
    let ast = syn::parse(input).unwrap();
    impl_get_all(&ast)
}

#[proc_macro_derive(Update)]
pub fn update_derive(input: TokenStream) -> TokenStream {
    let ast = syn::parse(input).unwrap();
    impl_update(&ast)
}

#[proc_macro_derive(Delete)]
pub fn delete_derive(input: TokenStream) -> TokenStream {
    let ast = syn::parse(input).unwrap();
    impl_delete(&ast)
}

#[proc_macro_derive(VerifyIdForUser)]
pub fn verify_id_for_user_derive(input: TokenStream) -> TokenStream {
    let ast = syn::parse(input).unwrap();
    impl_verify_id_for_user(&ast)
}

#[proc_macro_derive(VerifyIdForUserUnchecked)]
pub fn verify_it_for_user_unchecked_derive(input: TokenStream) -> TokenStream {
    let ast = syn::parse(input).unwrap();
    impl_verify_id_for_user_unchecked(&ast)
}

#[proc_macro_derive(VerifyIdForActionProvider)]
pub fn verify_id_for_action_provider_derive(input: TokenStream) -> TokenStream {
    let ast = syn::parse(input).unwrap();
    impl_verify_id_for_action_provider(&ast)
}

#[proc_macro_derive(VerifyIdForAdmin)]
pub fn verify_id_for_admin_derive(input: TokenStream) -> TokenStream {
    let ast = syn::parse(input).unwrap();
    impl_verify_id_for_admin(&ast)
}

#[proc_macro_derive(VerifyForUserWithDb)]
pub fn verify_for_user_with_db_derive(input: TokenStream) -> TokenStream {
    let ast = syn::parse(input).unwrap();
    impl_verify_for_user_with_db(&ast)
}

#[proc_macro_derive(VerifyForUserWithoutDb)]
pub fn verify_for_user_without_db_derive(input: TokenStream) -> TokenStream {
    let ast = syn::parse(input).unwrap();
    impl_verify_for_user_without_db(&ast)
}

#[proc_macro_derive(VerifyForActionProviderWithDb)]
pub fn verify_for_action_provider_with_db_derive(input: TokenStream) -> TokenStream {
    let ast = syn::parse(input).unwrap();
    impl_verify_for_action_provider_with_db(&ast)
}

#[proc_macro_derive(VerifyForActionProviderWithoutDb)]
pub fn verify_for_action_provider_without_db_derive(input: TokenStream) -> TokenStream {
    let ast = syn::parse(input).unwrap();
    impl_verify_for_action_provider_without_db(&ast)
}

#[proc_macro_derive(VerifyForActionProviderUnchecked)]
pub fn verify_for_admin_unchecked_derive(input: TokenStream) -> TokenStream {
    let ast = syn::parse(input).unwrap();
    impl_verify_for_action_provider_unchecked(&ast)
}

#[proc_macro_derive(VerifyForAdminWithoutDb)]
pub fn verify_for_admin_without_db_derive(input: TokenStream) -> TokenStream {
    let ast = syn::parse(input).unwrap();
    impl_verify_for_admin_without_db(&ast)
}

#[proc_macro_derive(InnerIntFromParam)]
pub fn inner_int_from_param_derive(input: TokenStream) -> TokenStream {
    let ast = syn::parse(input).unwrap();
    impl_inner_int_from_param(&ast)
}

#[proc_macro_derive(InnerIntToSql)]
pub fn unverfied_inner_int_to_sql(input: TokenStream) -> TokenStream {
    let ast = syn::parse(input).unwrap();
    impl_inner_int_to_sql(&ast)
}

#[proc_macro_derive(InnerIntFromSql)]
pub fn unverfied_inner_int_drom_sql(input: TokenStream) -> TokenStream {
    let ast = syn::parse(input).unwrap();
    impl_inner_int_from_sql(&ast)
}
