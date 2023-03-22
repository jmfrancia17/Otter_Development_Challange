public class OtterApplicationRequestBodyWrapper {

    public String companyName;
    public String email;
    public String phone;
    public List<ProductWrapper> selectedProducts;
    public AddressWrapper address;
    public String personalFirstName;
    public String personalLastName;
    
    public class ProductWrapper {
        public String uuid;
        public Integer quantity;
    }
    
    public class AddressWrapper {
        public String street;
        public String city;
        public String state;
        public String postalCode;
        public String country;
    }

    public static OtterApplicationRequestBodyWrapper deserialize(String jsonString) {
        return (OtterApplicationRequestBodyWrapper) JSON.deserialize(jsonString, OtterApplicationRequestBodyWrapper.class);
    }
}